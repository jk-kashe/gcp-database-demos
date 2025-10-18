data "google_project" "project" {}

# Grant the Compute Engine service account access to the GCS bucket
resource "google_storage_bucket_iam_member" "compute_gcs_access" {
  bucket = "${var.project_id}_cloudbuild"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    module.landing_zone.google_project_service.project_services["cloudbuild.googleapis.com"]
  ]
}

# Grant the Cloud Build service account access to the GCS bucket
resource "google_storage_bucket_iam_member" "cloudbuild_gcs_access" {
  bucket = "${var.project_id}_cloudbuild"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    module.landing_zone.google_project_service.project_services["cloudbuild.googleapis.com"]
  ]
}

# Grant the Compute Engine service account access to Artifact Registry
resource "google_project_iam_member" "compute_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Grant the Compute Engine service account access to write logs
resource "google_project_iam_member" "compute_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
