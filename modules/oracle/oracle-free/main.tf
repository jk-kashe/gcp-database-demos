terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Create a firewall rule to allow access to the Oracle database
resource "google_compute_firewall" "allow_oracle_vm" {
  name    = "allow-oracle-vm"
  network = var.network_name
  allow {
    protocol = "tcp"
    ports    = ["1521"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Create a Compute Engine instance with OS Login enabled
resource "google_compute_instance" "oracle_vm" {
  name         = "oracle-vm"
  machine_type = var.vm_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = 50
    }
  }

  # Enable OS Login for IAM-based SSH access
  metadata = {
    enable-oslogin = "TRUE"
  }

  # Enable Shielded VM features to comply with org policy
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    # No access_config block, so no external IP will be assigned
  }
}

# Wait for the instance to be fully ready for SSH
resource "time_sleep" "wait_for_vm_ssh" {
  create_duration = "180s"
  depends_on      = [google_compute_instance.oracle_vm]
}

resource "random_password" "apex_admin_password" {
  length  = 16
  special = false # Special characters can interfere with sed
}

resource "random_password" "db_user_password" {
  length  = 16
  special = false
}

locals {
  apex_admin_password_nonsensitive = nonsensitive(random_password.apex_admin_password.result)
  db_user_password_nonsensitive    = nonsensitive(random_password.db_user_password.result)
  vm_oracle_password_nonsensitive  = nonsensitive(var.vm_oracle_password)
}

# Provision the VM after the delay
resource "null_resource" "provision_db_vm" {
  depends_on = [time_sleep.wait_for_vm_ssh]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${google_compute_instance.oracle_vm.zone} --project=${var.project_id} --tunnel-through-iap --command='\
        sudo apt-get update && \
        sudo apt-get install -y docker.io && \
        curl -o /tmp/unattended_apex_install_23c.sh https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/unattended_apex_install_23c.sh && \
        curl -o /tmp/00_start_apex_ords_installer.sh https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/00_start_apex_ords_installer.sh && \
        sudo sed -i -e "s/$/ &/"; /tmp/00_start_apex_ords_installer.sh && \
        sudo sed -i "s/OrclAPEX1999!/${local.apex_admin_password_nonsensitive}/g" /tmp/unattended_apex_install_23c.sh && \
        sudo sed -i "s/ALTER USER APEX_PUBLIC_USER IDENTIFIED BY E;/ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ${local.db_user_password_nonsensitive};/g" /tmp/unattended_apex_install_23c.sh && \
        sudo sed -i "/<<EOT/,/EOT/ s/^E$/${local.db_user_password_nonsensitive}/" /tmp/unattended_apex_install_23c.sh && \
        sudo docker rm -f oracle-free || true && \
        sudo docker create --name oracle-free -p 1521:1521 -e ORACLE_PWD=${local.vm_oracle_password_nonsensitive} container-registry.oracle.com/database/free:latest && \
        sudo docker cp /tmp/unattended_apex_install_23c.sh oracle-free:/home/oracle/unattended_apex_install_23c.sh && \
        sudo docker cp /tmp/00_start_apex_ords_installer.sh oracle-free:/opt/oracle/scripts/startup/00_start_apex_ords_installer.sh && \
        sudo docker start oracle-free
      '
    EOT
  }
}

resource "time_sleep" "wait_for_apex_install" {
  create_duration = "300s"
  depends_on      = [null_resource.provision_db_vm]
}

resource "local_file" "sqlplus_client_script" {
  count    = var.client_script_path == null ? 0 : 1
  filename = var.client_script_path
  content  = <<-EOT
#!/bin/bash
# This script connects directly to the SQL*Plus client inside the Oracle VM's Docker container.
# You will be prompted for the password defined in the 'vm_oracle_password' Terraform variable.

gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${var.zone} --tunnel-through-iap --project ${var.project_id} -- -t "sudo docker exec -it oracle-free sqlplus system@//localhost:1521/FREEPDB1"
  EOT
}
