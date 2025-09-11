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

# Create a Compute Engine instance with OS Login enabled
resource "google_compute_instance" "oracle_vm" {
  name         = "oracle-vm"
  machine_type = var.vm_machine_type
  zone         = data.google_compute_zones.available.names[0] # Select the first available zone

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  # Enable OS Login for IAM-based SSH access
  metadata = {
    enable-oslogin = "TRUE"
  }

  network_interface {
    network    = google_compute_network.oracle.id
    subnetwork = google_compute_subnetwork.oracle.id
    access_config {
      // Ephemeral public IP
    }
  }

  # This provisioner will now use the default gcloud credentials of the user
  # running terraform, authenticating via OS Login and IAP.
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo docker run -d -p 1521:1521 -e ORACLE_PASSWORD=${var.vm_oracle_password} gvenzl/oracle-free:latest"
    ]
  }
}

# Output the public IP of the VM
output "oracle_vm_ip" {
  value = google_compute_instance.oracle_vm.network_interface[0].access_config[0].nat_ip
}