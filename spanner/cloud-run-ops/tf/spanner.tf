#Enable APIs
locals {
  spanner_apis_to_enable = [
    "spanner.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]

  spanner_config = var.spanner_config == null ? "regional-${var.regions[0]}" : var.spanner_config
}

resource "google_project_service" "spanner_services" {
  for_each           = toset(local.spanner_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}

# Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  config           = local.spanner_config
  display_name     = var.spanner_instance_name
  project          = local.project_id
  processing_units = var.spanner_nodes < 1 ? var.spanner_nodes * 1000 : null
  num_nodes        = var.spanner_nodes < 1 ? null : var.spanner_nodes
  depends_on       = [google_project_service.spanner_services]
  edition          = var.spanner_edition
}

resource "google_spanner_database" "spanner_demo_db" {
  project             = local.project_id
  name                = var.spanner_database_name
  instance            = google_spanner_instance.spanner_instance.name
  deletion_protection = false
}

locals {
  spanner_instance_id = split("/", google_spanner_instance.spanner_instance.id)[1]
  spanner_database_id = split("/", google_spanner_database.spanner_demo_db.id)[1]
}

#Add required roles to the default compute SA (used by spanner dataflow import)
locals {
  default_compute_sa_roles_dataflow_import = [
    "roles/dataflow.worker",
    "roles/spanner.databaseAdmin"
  ]
}

resource "google_project_iam_member" "spanner_dataflow_import_sa_roles" {
  for_each   = toset(local.default_compute_sa_roles_dataflow_import)
  project    = local.project_id
  role       = each.key
  member     = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}