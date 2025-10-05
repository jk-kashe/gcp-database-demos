resource "local_file" "tools_yaml" {
  content = <<-EOT
    sources:
      pagila:
        kind: postgres
        host: ${module.alloydb.primary_instance.ip_address}
        port: 5432
        database: pagila
        user: postgres
        password: ${var.alloydb_password}
  EOT
  filename = "${path.module}/tools.yaml"
}

resource "google_service_account" "mcp_server_identity" {
  account_id   = "mcp-server-identity"
  display_name = "MCP Server Identity"
  project      = module.landing_zone.project_id
}

resource "google_project_iam_member" "mcp_server_secret_accessor" {
  project = module.landing_zone.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.mcp_server_identity.email}"
}

resource "google_project_iam_member" "mcp_server_alloydb_client" {
  project = module.landing_zone.project_id
  role    = "roles/alloydb.client"
  member  = "serviceAccount:${google_service_account.mcp_server_identity.email}"
}

resource "google_project_iam_member" "mcp_server_alloydb_viewer" {
  project = module.landing_zone.project_id
  role    = "roles/alloydb.viewer"
  member  = "serviceAccount:${google_service_account.mcp_server_identity.email}"
}

resource "google_secret_manager_secret" "mcp_tools_yaml_secret" {
  secret_id = "mcp-tools-yaml"
  project   = module.landing_zone.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mcp_tools_yaml_secret_version" {
  secret      = google_secret_manager_secret.mcp_tools_yaml_secret.id
  secret_data = local_file.tools_yaml.content
}

resource "google_vpc_access_connector" "mcp_server_vpc_connector" {
  name          = "mcp-server-vpc-connector"
  project       = module.landing_zone.project_id
  region        = var.region
  network       = module.landing_zone.demo_network.name
  ip_cidr_range = "10.8.0.0/28"
}

resource "google_cloud_run_v2_service" "mcp_server" {
  name     = "mcp-server"
  location = var.region
  project  = module.landing_zone.project_id

  depends_on = [
    null_resource.pagila_db_setup,
    google_project_iam_member.mcp_server_secret_accessor,
    google_project_iam_member.mcp_server_alloydb_client,
    google_project_iam_member.mcp_server_alloydb_viewer
  ]

  template {
    service_account = google_service_account.mcp_server_identity.email

    containers {
      image = "us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest"
      args  = ["--tools-file=/app/tools.yaml", "--address=0.0.0.0", "--port=8080"]

      volume_mounts {
        name = "tools-yaml"
        mount_path = "/app"
      }
    }

    volumes {
      name = "tools-yaml"
      secret {
        secret = google_secret_manager_secret.mcp_tools_yaml_secret.secret_id
        items {
          path = "tools.yaml"
          version = google_secret_manager_secret_version.mcp_tools_yaml_secret_version.version
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.mcp_server_vpc_connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}
