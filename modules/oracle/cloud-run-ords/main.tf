# Enable APIs
resource "google_project_service" "api" {
  for_each = toset(var.apis)

  service            = each.value
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_api" {
  create_duration = "60s"

  depends_on = [google_project_service.api]
}

data "google_project" "project" {}

resource "google_cloud_run_v2_service" "ords" {
  provider = google-beta
  name     = "ords"
  location = var.region
  deletion_protection = false
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA"

  template {
    containers {
      # Use the official Oracle ORDS container image with the version matching the VM
      image = "container-registry.oracle.com/database/ords:${var.ords_container_tag}"

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
      # Provide the SYS password for the initial installation
      env {
        name = "ORACLE_PWD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.vm_oracle_password.secret_id
            version = "latest"
          }
        }
      }
      # Provide the password for the other database users that will be configured
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

      resources {
        limits = {
          memory = "2Gi"
          cpu    = "1"
        }
      }
    }

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    var.db_instance_dependency
  ]
}

# Create Secret Manager secrets for the passwords
resource "google_secret_manager_secret" "vm_oracle_password" {
  secret_id = "vm_oracle_password"
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
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_user_password_version" {
  secret      = google_secret_manager_secret.db_user_password.id
  secret_data = var.db_user_password
}

# Grant the Cloud Run service account access to the secrets
resource "google_project_service_identity" "run_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "run.googleapis.com"

  depends_on = [google_project_service.api["run.googleapis.com"]]
}

resource "google_secret_manager_secret_iam_member" "oracle_password_accessor" {
  secret_id = google_secret_manager_secret.vm_oracle_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.run_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "db_password_accessor" {
  secret_id = google_secret_manager_secret.db_user_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.run_sa.email}"
}
