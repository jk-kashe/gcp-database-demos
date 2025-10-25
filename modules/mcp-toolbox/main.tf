terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

resource "google_service_account" "mcp_toolbox_identity" {
  account_id   = var.service_account_id
  display_name = "MCP Toolbox Identity"
  project      = var.project_id
}

resource "google_project_iam_member" "mcp_toolbox_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mcp_toolbox_identity.email}"
}

resource "google_project_iam_member" "extra_roles" {
  for_each = toset(var.extra_service_account_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.mcp_toolbox_identity.email}"
}

resource "google_project_service" "secretmanager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "mcp_toolbox_tools_yaml_secret" {
  secret_id = "${var.service_name}-tools-yaml"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "mcp_toolbox_tools_yaml_secret_version" {
  secret      = google_secret_manager_secret.mcp_toolbox_tools_yaml_secret.id
  secret_data = var.tools_yaml_content
}


resource "google_cloud_run_v2_service" "mcp_toolbox" {
  provider            = google-beta
  name                = var.service_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  iap_enabled         = true

  depends_on = [
    google_project_iam_member.mcp_toolbox_secret_accessor,
    google_project_iam_member.extra_roles
  ]

  template {
    service_account = google_service_account.mcp_toolbox_identity.email

    containers {
      image = var.container_image
      args  = ["--tools-file=/app/tools.yaml", "--address=0.0.0.0", "--port=8080", "--log-level=DEBUG"]

      volume_mounts {
        name       = "tools-yaml"
        mount_path = "/app"
      }
    }

    volumes {
      name = "tools-yaml"
      secret {
        secret = google_secret_manager_secret.mcp_toolbox_tools_yaml_secret.secret_id
        items {
          path    = "tools.yaml"
          version = google_secret_manager_secret_version.mcp_toolbox_tools_yaml_secret_version.version
        }
      }
    }

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }
  }
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  provider = google-beta
  project  = google_cloud_run_v2_service.mcp_toolbox.project
  location = google_cloud_run_v2_service.mcp_toolbox.location
  name     = google_cloud_run_v2_service.mcp_toolbox.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
  depends_on = [google_cloud_run_v2_service.mcp_toolbox]
}



resource "google_cloud_run_service_iam_member" "mcp_toolbox_invoker" {
  for_each = toset(var.invoker_users)
  location = google_cloud_run_v2_service.mcp_toolbox.location
  project  = google_cloud_run_v2_service.mcp_toolbox.project
  service  = google_cloud_run_v2_service.mcp_toolbox.name
  role     = "roles/run.invoker"
  member   = each.value
}
