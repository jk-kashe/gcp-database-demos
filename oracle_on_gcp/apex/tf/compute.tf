# Client VM
data "google_compute_zones" "available" {
  status = "UP"
  depends_on = [ time_sleep.wait_for_api ]
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

resource "google_service_account" "oracle_client" {
  account_id   = "oracle-client"
  display_name = "Oracle Client"
}

resource "google_project_iam_member" "oracle_client" {
  project = var.project_id
  role    = "roles/oracledatabase.autonomousDatabaseViewer"
  member  = google_service_account.oracle_client.member
}

resource "google_compute_instance" "oracle_client" {
  depends_on = [google_compute_instance.oracle_vm]

  name         = "oracle-client-vm"
  zone         = random_shuffle.zone.result[0]
  machine_type = "n2-standard-2"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 10
      type  = "pd-standard"
    }
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

  service_account {
    email  = google_service_account.oracle_client.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script-url = "https://storage.googleapis.com/oracle-partner-demo-bucket/startup-scripts/ubuntu-oracle-startup-script.sh"
  }
}

resource "time_sleep" "wait_for_oracle_client_startup_script" {
  create_duration = "120s"

  depends_on = [google_compute_instance.oracle_client]
}

# Generate SSH keys
resource "null_resource" "init_gcloud_ssh" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud compute config-ssh
    EOT
  }
  depends_on = [ time_sleep.wait_for_api ]
}
