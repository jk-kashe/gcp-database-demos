#Provision Client VM
resource "google_compute_instance" "database-clientvm" {
  depends_on = [ google_project_service.project_services ]
  
  name         = var.clientvm-name
  machine_type = "e2-medium"
  zone         = "${var.region}-${var.zone}" 
  project      = local.project_id
 

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240617"
    }
  }

  network_interface {
    network = google_compute_network.demo_network.id
  }

  service_account {
    email  = "${local.project_number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

}

#this is just to make sure we have ssh keys
resource "null_resource" "lz-init-gcloud-ssh" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud compute config-ssh
    EOT
  }

  depends_on = [ google_project_service.project_services ]
}

resource "time_sleep" "wait_for_database_clientvm_boot" {
  create_duration = "120s"  # Adjust the wait time based on your VM boot time

  depends_on = [google_compute_instance.database-clientvm,
                null_resource.lz-init-gcloud-ssh]
}