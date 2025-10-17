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

# Provision the VM after the delay
resource "null_resource" "provision_db_vm" {
  depends_on = [time_sleep.wait_for_vm_ssh]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${google_compute_instance.oracle_vm.zone} --project=${var.project_id} --tunnel-through-iap --command='sudo apt-get update && sudo apt-get install -y docker.io && sudo docker run -d --name oracle-free -p 1521:1521 -e ORACLE_PASSWORD=${var.vm_oracle_password} gvenzl/oracle-free:latest'
    EOT
  }
}

resource "local_file" "sqlplus_client_script" {
  count    = var.client_script_path == null ? 0 : 1
  filename = var.client_script_path
  content  = <<-EOT
#!/bin/bash
# This script connects directly to the SQL*Plus client inside the Oracle VM's Docker container.
# You will be prompted for the password defined in the 'vm_oracle_password' Terraform variable.

gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${var.zone} --tunnel-through-iap --project ${var.project_id} --command "sudo docker exec -it oracle-free sqlplus system@//localhost:1521/FREEPDB1"
  EOT
}