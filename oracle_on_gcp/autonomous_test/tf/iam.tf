# GCS bucket for Cloud Build source archives
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "google_storage_bucket" "cloudbuild_bucket" {
  name          = "${var.project_id}-cloudbuild-${random_string.bucket_suffix.result}"
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

# Grant the Compute Engine SA permissions as a workaround for the build error
resource "google_storage_bucket_iam_member" "compute_gcs_access_workaround" {
  bucket = google_storage_bucket.cloudbuild_bucket.name
  role   = "roles/storage.objectAdmin" # Granting Admin to be safe, covers get/list/create
  member = "serviceAccount:${module.landing_zone.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [google_storage_bucket.cloudbuild_bucket]
}

resource "google_project_iam_member" "compute_ar_writer_workaround" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${module.landing_zone.project_number}-compute@developer.gserviceaccount.com"
}

resource "time_sleep" "wait_for_iam_propagation" {
  create_duration = "30s"

  depends_on = [
    google_storage_bucket_iam_member.cloudbuild_gcs_access,
    google_project_iam_member.cloudbuild_ar_writer,
    google_storage_bucket_iam_member.compute_gcs_access_workaround,
    google_project_iam_member.compute_ar_writer_workaround
  ]
}
