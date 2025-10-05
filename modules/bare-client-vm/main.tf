#Provision Client VM
resource "google_compute_instance" "database-clientvm" {
  depends_on = [var.project_services_dependency]

  name         = var.clientvm-name
  machine_type = "e2-medium"
  zone         = "${var.region}-${var.zone}"
  project      = var.project_id


  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240617"
    }
  }

  network_interface {
    network = var.network_id
  }

  service_account {
    email  = "${var.project_number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

}
