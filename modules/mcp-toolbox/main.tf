terraform {
  required_providers {
    google-beta = {
      source = "hashicorp/google-beta"
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

module "cr_base" {
  source = "../cr-base"

  project_id            = var.project_id
  region                = var.region
  service_name          = var.service_name
  container_image       = var.container_image
  service_account_email = google_service_account.mcp_toolbox_identity.email
  vpc_connector_id      = var.vpc_connector_id
  invoker_users         = var.invoker_users
  use_iap               = false

  container_args = ["--tools-file=/app/tools.yaml", "--address=0.0.0.0", "--port=8080", "--log-level=DEBUG"]

  template_volumes = [{
    name = "tools-yaml"
    secret = {
      secret = google_secret_manager_secret.mcp_toolbox_tools_yaml_secret.secret_id
      items = [{
        path    = "tools.yaml"
        version = google_secret_manager_secret_version.mcp_toolbox_tools_yaml_secret_version.version
      }]
    }
  }]

  container_volume_mounts = [{
    name       = "tools-yaml"
    mount_path = "/app"
  }]

  depends_on = [
    google_project_iam_member.mcp_toolbox_secret_accessor,
    google_project_iam_member.extra_roles
  ]
}

resource "local_file" "update_settings_sh" {
  count = var.generate_gemini_config ? 1 : 0

  content = templatefile("${path.module}/templates/update_settings.sh.tpl", {
    mcp_server_url  = module.cr_base.service_url,
    mcp_server_name = var.service_name,
    config_path     = abspath(var.gemini_config_path)
  })
  filename = var.update_script_path
}

resource "null_resource" "run_update_settings" {
  count = var.generate_gemini_config ? 1 : 0
  depends_on = [local_file.update_settings_sh, module.cr_base]

  provisioner "local-exec" {
    command = "chmod +x ${local_file.update_settings_sh[0].filename} && ${local_file.update_settings_sh[0].filename}"
  }
}