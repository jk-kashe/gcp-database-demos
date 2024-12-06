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


# Service Account Creation for the cloud run middleware retrieval service 
resource "google_service_account" "cloudrun_identity" {
  account_id   = "cloudrun-identity"
  display_name = "CloudRun Identity"
  project      = local.project_id
  depends_on   = [ google_project_service.project_services ]
}

# Roles for retrieval identity
locals {
  cloudrun_identity_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
    "roles/aiplatform.user",
    "roles/spanner.databaseUser"
  ]
}

resource "google_project_iam_member" "cloudrun_identity_aiplatform_user" {
  for_each   = toset(local.cloudrun_identity_roles)
  role       = each.key
  member     = "serviceAccount:${google_service_account.cloudrun_identity.email}"
  project    = local.project_id

  depends_on = [ google_service_account.cloudrun_identity,
                 google_project_service.project_services ]
}


#it takes a while for the SA roles to be applied
resource "time_sleep" "wait_for_sa_roles_expanded" {
  create_duration = "120s"  

  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}


# Artifact Registry Repository (If not created previously)
resource "google_artifact_registry_repository" "demo_service_repo" {
  depends_on    = [time_sleep.wait_for_sa_roles_expanded,
                   google_project_service.project_services]                                     #20-landing-zone-apis.tf
  provider      = google-beta
  location      = var.region
  repository_id = "demo-service-repo"
  description   = "Artifact Registry repository for the demo service(s)"
  format        = "DOCKER"
  project       = local.project_id
}


#for public cloud run deployments
#use the commented block aftert this
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# this is an example config for noauth policy
# just copy and change service name
# resource "google_cloud_run_service_iam_policy" "noauth" {
#   location    = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
#   project     = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
#   service     = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

#   policy_data = data.google_iam_policy.noauth.policy_data
# }