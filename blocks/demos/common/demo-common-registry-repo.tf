# Depends on:
# 05-landing-zone-existing-project.tf | 05-landing-zone-new-project.tf
# 20-landing-zone-apis.tf
# 30-landing-zone-clientvm.tf

#Add required roles to the default compute SA (used by clientVM and Cloud Build)
locals {
  default_compute_sa_roles_expanded = [
    "roles/cloudbuild.builds.editor",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "default_compute_sa_roles_expanded" {
  for_each = toset(local.default_compute_sa_roles_expanded)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]                                     #30-landing-zone-clientvm.tf
}


#it takes a while for the SA roles to be applied
resource "time_sleep" "wait_for_sa_roles_expanded" {
  create_duration = "120s"  

  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}


# Artifact Registry Repository (If not created previously)
resource "google_artifact_registry_repository" "retrieval_service_repo" {
  depends_on    = [time_sleep.wait_for_sa_roles_expanded,
                   google_project_service.project_services]                                     #20-landing-zone-apis.tf
  provider      = google-beta
  location      = var.region
  repository_id = "retrieval-service-repo"
  description   = "Artifact Registry repository for the retrieval service"
  format        = "DOCKER"
  project       = local.project_id
}