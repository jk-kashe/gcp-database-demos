#Enable APIs
locals {
  spanner_apis_to_enable = [
    "spanner.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "spanner_services" {
  for_each           = toset(local.spanner_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}
