data "google_project" "project_check" {
  project_id = var.demo_project_id
}

locals {
  project_id     = data.google_project.project_check.project_id
  project_name   = data.google_project.project_check.name
  project_number = data.google_project.project_check.number
}

output "project_id" {
  value = local.project_id
}