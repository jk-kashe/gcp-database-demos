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

  metadata = {
    enable-oslogin = "TRUE"
    enable-guest-attributes = "TRUE"
    startup-script = templatefile("${path.module}/templates/startup.sh.tpl", {
      apex_admin_password = random_password.apex_admin_password.result,
      db_user_password    = random_password.db_user_password.result,
      vm_oracle_password  = var.vm_oracle_password,
      gcs_bucket_name     = var.gcs_bucket_name,
      vm_name             = self.name
    })
  }

  service_account {
    scopes = ["cloud-platform"]
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

resource "random_password" "apex_admin_password" {
  length  = 16
  special = false # Special characters can interfere with sed
}

resource "random_password" "db_user_password" {
  length  = 16
  special = false
}

resource "time_sleep" "wait_for_startup_script" {
  create_duration = "300s"
  depends_on      = [google_compute_instance.oracle_vm]
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

resource "local_file" "ords_connect_script" {
  count    = var.client_script_path == null ? 0 : 1
  filename = "${dirname(var.client_script_path)}/ords-connect.sh"
  content  = templatefile("${path.module}/templates/ords-connect.sh.tpl", {
    vm_name    = google_compute_instance.oracle_vm.name,
    zone       = var.zone,
    project_id = var.project_id
  })
}

resource "null_resource" "make_scripts_executable" {
  count = var.client_script_path == null ? 0 : 1

  triggers = {
    sqlplus_script = local_file.sqlplus_client_script[0].filename
    ords_script    = local_file.ords_connect_script[0].filename
  }

  provisioner "local-exec" {
    command = "chmod +x ${local_file.sqlplus_client_script[0].filename} && chmod +x ${local_file.ords_connect_script[0].filename}"
  }

  depends_on = [
    local_file.sqlplus_client_script,
    local_file.ords_connect_script
  ]
}
