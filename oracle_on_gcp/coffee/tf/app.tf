# Repository
resource "google_artifact_registry_repository" "container_images" {
  depends_on = [time_sleep.wait_for_api]

  location               = var.region
  repository_id          = "container-images"
  description            = "Artifact Registry repository for container images"
  format                 = "DOCKER"
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }
}

# API key
resource "random_string" "coffee_apikey_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_apikeys_key" "coffee" {
  depends_on   = [time_sleep.wait_for_api]
  name         = "coffee-${random_string.coffee_apikey_suffix.result}"
  display_name = "coffee"

  restrictions {
    api_targets {
      service = "aiplatform.googleapis.com"
    }
  }
}

resource "google_secret_manager_secret" "coffee_api_key" {
  depends_on = [time_sleep.wait_for_api]

  secret_id = "coffee-api-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "coffee_api_key" {
  depends_on = [time_sleep.wait_for_api]

  secret      = google_secret_manager_secret.coffee_api_key.id
  secret_data = google_apikeys_key.coffee.key_string
}

# Service account
resource "google_service_account" "coffee" {
  account_id   = "coffee"
  display_name = "Coffee"
}

resource "google_project_iam_member" "coffee" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = google_service_account.coffee.member
}

resource "google_secret_manager_secret_iam_member" "coffee_oracle_database_url" {
  secret_id = google_secret_manager_secret.oracle_database_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.coffee.member
}

resource "google_secret_manager_secret_iam_member" "coffee_api_key" {
  secret_id = google_secret_manager_secret.coffee_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.coffee.member
}

resource "google_secret_manager_secret_iam_member" "coffee_secret_key" {
  secret_id = google_secret_manager_secret.coffee_secret_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.coffee.member
}

# Build
locals {
  coffee_image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_images.repository_id}/coffee:latest"
}

resource "null_resource" "coffee_build" {
  depends_on = [time_sleep.wait_for_api]

  provisioner "local-exec" {
    command = <<EOT
      rm -rf oracledb-vertexai-demo
      git clone ${var.git_repo}
      cd oracledb-vertexai-demo
      git checkout ${var.git_branch}
      cd ..
      gcloud builds submit oracledb-vertexai-demo/app --tag ${local.coffee_image}
      rm -rf oracledb-vertexai-demo
    EOT
  }
}

# Cloud Run service
resource "random_password" "coffee_secret_key" {
  length  = 32
  special = false
}

resource "google_secret_manager_secret" "coffee_secret_key" {
  depends_on = [time_sleep.wait_for_api]

  secret_id = "coffee-secret-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "coffee_secret_key" {
  secret      = google_secret_manager_secret.coffee_secret_key.id
  secret_data = random_password.coffee_secret_key.result
}

resource "google_cloud_run_v2_service" "coffee" {
  depends_on          = [null_resource.load_coffee_data, null_resource.coffee_build]
  deletion_protection = false

  name     = "coffee"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = local.coffee_image

      ports {
        container_port = 8080
      }

      env {
        name = "DATABASE_URL"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.oracle_database_url.secret_id
            version = google_secret_manager_secret_version.oracle_database_url.version
          }
        }
      }

      env {
        name  = "ORACLE_TNSNAMES"
        value = "${google_oracle_database_autonomous_database.oracle.autonomous_database_id} = ${local.oracle_profiles.high.value}"
      }

      env {
        name  = "TNS_ADMIN"
        value = "/app"
      }

      env {
        name  = "GOOGLE_PROJECT_ID"
        value = var.project_id
      }

      env {
        name = "GOOGLE_API_KEY"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.coffee_api_key.secret_id
            version = google_secret_manager_secret_version.coffee_api_key.version
          }
        }
      }

      env {
        name  = "LITESTAR_DEBUG"
        value = "true"
      }

      env {
        name  = "LITESTAR_HOST"
        value = "0.0.0.0"
      }

      env {
        name  = "LITESTAR_GRANIAN_IN_SUBPROCESS"
        value = "false"
      }

      env {
        name  = "LITESTAR_GRANIAN_USE_LITESTAR_LOGGER"
        value = "true"
      }

      env {
        name = "SECRET_KEY"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.coffee_secret_key.secret_id
            version = google_secret_manager_secret_version.coffee_secret_key.version
          }
        }
      }
    }

    service_account = google_service_account.coffee.email

    vpc_access {
      network_interfaces {
        network    = google_compute_network.oracle.id
        subnetwork = google_compute_subnetwork.oracle.id
      }
    }
  }
}

# Allow public access to the app
resource "google_cloud_run_v2_service_iam_member" "coffee_public" {
  name   = google_cloud_run_v2_service.coffee.name
  role   = "roles/run.invoker"
  member = "allUsers"
}
