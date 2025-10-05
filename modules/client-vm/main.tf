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

#this is just to make sure we have ssh keys
resource "null_resource" "lz-init-gcloud-ssh" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud compute config-ssh
    EOT
  }

  depends_on = [var.project_services_dependency]
}

resource "time_sleep" "wait_for_database_clientvm_boot" {
  create_duration = "120s" # Adjust the wait time based on your VM boot time

  depends_on = [google_compute_instance.database-clientvm,
  null_resource.lz-init-gcloud-ssh]
}

#Add required roles to the default compute SA (used by clientVM and Cloud Build)
locals {
  default_compute_sa_roles_expanded = [
    "roles/cloudbuild.builds.editor",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "default_compute_sa_roles_expanded" {
  for_each   = toset(local.default_compute_sa_roles_expanded)
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}
