terraform {
  required_providers {
    google-beta = {
      source = "hashicorp/google-beta"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_cloud_run_v2_service" "iap_service" {
  provider            = google-beta
  name                = var.service_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  iap_enabled         = var.use_iap
  launch_stage        = "BETA"

  template {
    service_account = var.service_account_email

    containers {
      image = var.container_image
      args  = var.container_args
      ports {
        container_port = var.container_port
      }

      dynamic "volume_mounts" {
        for_each = var.container_volume_mounts
        content {
          name       = volume_mounts.value.name
          mount_path = volume_mounts.value.mount_path
        }
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.value.name
          value = lookup(env.value, "value", null)
          dynamic "value_source" {
            for_each = lookup(env.value, "value_source", null) != null ? [env.value.value_source] : []
            content {
              secret_key_ref {
                secret  = value_source.value.secret_key_ref.secret
                version = value_source.value.secret_key_ref.version
              }
            }
          }
        }
      }
    }

    dynamic "volumes" {
      for_each = var.template_volumes
      content {
        name = volumes.value.name
        dynamic "secret" {
          for_each = lookup(volumes.value, "secret", null) != null ? [volumes.value.secret] : []
          content {
            secret = secret.value.secret
            dynamic "items" {
              for_each = lookup(secret.value, "items", [])
              content {
                path    = items.value.path
                version = items.value.version
              }
            }
          }
        }
        dynamic "gcs" {
          for_each = lookup(volumes.value, "gcs", null) != null ? [volumes.value.gcs] : []
          content {
            bucket    = gcs.value.bucket
            read_only = lookup(gcs.value, "read_only", false)
          }
        }
      }
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = "ALL_TRAFFIC"
      }
    }
  }
}



data "google_project" "project" {
  project_id = var.project_id
}

# Allow IAP to invoke the service
resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  count    = var.use_iap ? 1 : 0
  provider = google-beta
  project  = google_cloud_run_v2_service.iap_service.project
  location = google_cloud_run_v2_service.iap_service.location
  name     = google_cloud_run_v2_service.iap_service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
}

# Allow specified users to invoke the service
resource "google_cloud_run_service_iam_member" "user_invokers" {
  for_each = toset(var.invoker_users)
  location = google_cloud_run_v2_service.iap_service.location
  project  = google_cloud_run_v2_service.iap_service.project
  service  = google_cloud_run_v2_service.iap_service.name
  role     = "roles/run.invoker"
  member   = each.value
}
