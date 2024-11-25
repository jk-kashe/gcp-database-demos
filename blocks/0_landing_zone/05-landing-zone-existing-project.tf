resource "null_resource" "enable_service_usage_api_pre_proj" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com --project ${var.demo_project_id}"
  }
}

resource "google_project_service" "project_rm_api" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api_pre_proj]
  project            = var.demo_project_id
}

data "google_project" "project_check" {
  project_id = var.demo_project_id
  depends_on = [google_project_service.project_rm_api]
}

locals {
  project_id     = data.google_project.project_check.project_id
  project_name   = data.google_project.project_check.name
  project_number = data.google_project.project_check.number
}

output "project_id" {
  value = local.project_id
}