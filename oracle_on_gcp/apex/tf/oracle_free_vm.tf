# Create a firewall rule to allow access to the Oracle database
resource "google_compute_firewall" "allow_oracle_vm" {
  name    = "allow-oracle-vm"
  network = google_compute_network.oracle.name
  allow {
    protocol = "tcp"
    ports    = ["1521"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Create a firewall rule to allow access to APEX
resource "google_compute_firewall" "allow_apex_vm" {
  name    = "allow-apex-vm"
  network = google_compute_network.oracle.name
  allow {
    protocol = "tcp"
    ports    = ["8181"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apex-vm"]
}

# Create a Compute Engine instance with OS Login enabled
resource "google_compute_instance" "oracle_vm" {
  name         = "oracle-vm"
  machine_type = var.vm_machine_type
  zone         = data.google_compute_zones.available.names[0] # Select the first available zone
  tags         = ["apex-vm"]

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
    network    = google_compute_network.oracle.id
    subnetwork = google_compute_subnetwork.oracle.id
    # No access_config block, so no external IP will be assigned
  }
}

# Wait for the instance to be fully ready for SSH
resource "time_sleep" "wait_for_vm_ssh" {
  create_duration = "90s"
  depends_on      = [google_compute_instance.oracle_vm]
}

# Provision the VM after the delay
resource "null_resource" "provision_oracle_vm" {
  depends_on = [time_sleep.wait_for_vm_ssh]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${google_compute_instance.oracle_vm.zone} --project=${var.project_id} --tunnel-through-iap --command='sudo apt-get update && sudo apt-get install -y docker.io && sudo docker network create apex-net && sudo docker run -d --name oracle-free --network apex-net -p 1521:1521 -e ORACLE_PASSWORD=${var.vm_oracle_password} gvenzl/oracle-free:latest'
    EOT
  }
}

# Provision the APEX container
resource "null_resource" "provision_apex_vm" {
  depends_on = [null_resource.provision_oracle_vm]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${google_compute_instance.oracle_vm.name} --zone=${google_compute_instance.oracle_vm.zone} --project=${var.project_id} --tunnel-through-iap --command='sudo docker run -d --name ords --network apex-net -p 8181:8181 --restart always -e DB_HOSTNAME=oracle-free -e DB_PORT=1521 -e DB_SERVICENAME=FREEPDB1 -e ORACLE_PASSWORD=${var.vm_oracle_password} container-registry.oracle.com/database/ords-developer:24.4.0'
    EOT
  }
}