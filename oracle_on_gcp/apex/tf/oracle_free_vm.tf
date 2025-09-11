
# Create a firewall rule to allow SSH access
resource "google_compute_firewall" "allow_ssh_vm" {
  name    = "allow-ssh-vm"
  network = google_compute_network.oracle.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

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

# Create a Compute Engine instance
resource "google_compute_instance" "oracle_vm" {
  name         = "oracle-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.oracle.id
    subnetwork = google_compute_subnetwork.oracle.id
    access_config {
      // Ephemeral public IP
    }
  }

  # Use a provisioner to install Docker and run the Oracle container
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo docker run -d -p 1521:1521 -e ORACLE_PASSWORD=your_password gvenzl/oracle-free:latest"
    ]

    connection {
      type        = "ssh"
      user        = "your_user" # Replace with your SSH user
      private_key = file("~/.ssh/google_compute_engine") # Replace with your private key path
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

# Output the public IP of the VM
output "oracle_vm_ip" {
  value = google_compute_instance.oracle_vm.network_interface[0].access_config[0].nat_ip
}
