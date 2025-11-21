# GCS bucket for Cloud Build source archives
resource "google_storage_bucket" "cloudbuild_bucket" {
  name          = "${var.project_id}_cloudbuild"
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# Grant the Cloud Build service account access to read from the GCS bucket
resource "google_storage_bucket_iam_member" "cloudbuild_gcs_access" {
  bucket = google_storage_bucket.cloudbuild_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.landing_zone.project_number}@cloudbuild.gserviceaccount.com"
  depends_on = [google_storage_bucket.cloudbuild_bucket]
}

# Grant the Cloud Build service account access to write to Artifact Registry
resource "google_project_iam_member" "cloudbuild_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${module.landing_zone.project_number}@cloudbuild.gserviceaccount.com"
}
