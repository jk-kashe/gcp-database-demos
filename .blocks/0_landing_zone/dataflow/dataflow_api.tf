
resource "google_project_service" "lz_dataflow_service" {
  service            = "dataflow.googleapis.com"
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}