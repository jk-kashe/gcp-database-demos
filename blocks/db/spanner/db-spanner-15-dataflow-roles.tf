#Add required roles to the default compute SA (used by spanner dataflow import)
locals {
  default_compute_sa_roles_dataflow_import = [
    "roles/dataflow.worker"
  ]
}

resource "google_project_iam_member" "spanner_dataflow_import_sa_roles" {
  for_each = toset(local.default_compute_sa_roles_dataflow_import)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]                                     #30-landing-zone-clientvm.tf
}