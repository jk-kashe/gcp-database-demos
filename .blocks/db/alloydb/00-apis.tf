#Enable APIs
locals {
  alloydb_apis_to_enable = [
    "alloydb.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "alloydb_services" {
  for_each           = toset(local.alloydb_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}

