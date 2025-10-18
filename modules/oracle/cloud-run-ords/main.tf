# Enable APIs
resource "google_project_service" "api" {
  for_each = toset([
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
}

# Repository for the custom ORDS container image
resource "google_artifact_registry_repository" "ords_custom" {
  location      = var.region
  repository_id = "ords-custom"
  description   = "Repository for custom ORDS container images"
  format        = "DOCKER"
  depends_on    = [google_project_service.api["artifactregistry.googleapis.com"]]
}

# Build the custom ORDS container image using Cloud Build
resource "null_resource" "ords_container_build" {
  triggers = {
    # Re-run the build if the version changes
    ords_version = var.ords_container_tag
  }

  provisioner "local-exec" {
    # Use cloudbuild.yaml and substitutions to correctly pass the version to the build process.
    command = "gcloud builds submit --config ${path.module}/files/ords-container/cloudbuild.yaml --substitutions=_TAG='${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:${var.ords_container_tag}',_ORDS_VERSION='${var.ords_container_tag}' ${path.module}/files/ords-container"
  }

  depends_on = [
    google_artifact_registry_repository.ords_custom,
    var.iam_dependency
  ]
}

# Create Secret Manager secrets for the passwords
resource "google_secret_manager_secret" "vm_oracle_password" {
  secret_id = "vm_oracle_password"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "vm_oracle_password_version" {
  secret      = google_secret_manager_secret.vm_oracle_password.id
  secret_data = var.vm_oracle_password
}

resource "google_secret_manager_secret" "db_user_password" {
  secret_id = "db_user_password"
  project   = var.project_id
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_user_password_version" {
  secret      = google_secret_manager_secret.db_user_password.id
  secret_data = var.db_user_password
}

# Grant the default Compute Engine service account (used by Cloud Run by default) access to the secrets
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_secret_manager_secret_iam_member" "oracle_password_accessor" {
  secret_id = google_secret_manager_secret.vm_oracle_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_secret_manager_secret_iam_member" "db_password_accessor" {
  secret_id = google_secret_manager_secret.db_user_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Deploy the built container to Cloud Run
resource "google_cloud_run_v2_service" "ords" {
  name     = "ords"
  location = var.region
  project  = var.project_id
  deletion_protection = false

  template {
    scaling {
      max_instance_count = 1
    }
    containers {
      image = "${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:${var.ords_container_tag}"
      ports {
        container_port = 8080
      }
      env {
        name  = "DBHOST"
        value = var.oracle_db_ip
      }
      env {
        name  = "DBPORT"
        value = "1521"
      }
      env {
        name  = "DBSERVICE"
        value = "FREEPDB1"
      }
      env {
        name = "ORACLE_PWD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.vm_oracle_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "ORDS_PUBLIC_USER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "APEX_PUBLIC_USER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "APEX_LISTENER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "APEX_REST_PUBLIC_USER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user_password.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "ORDS_METADATA_USER_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_user_password.secret_id
            version = "latest"
          }
        }
      }
    }
    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    var.db_instance_dependency,
    null_resource.ords_container_build,
    google_secret_manager_secret_iam_member.oracle_password_accessor,
    google_secret_manager_secret_iam_member.db_password_accessor
  ]
}