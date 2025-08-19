# Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  config           = var.spanner_config == null ? "regional-${var.region}" : var.spanner_config
  display_name     = "${var.spanner_instance_name}"
  project          = local.project_id
  processing_units = var.spanner_nodes < 1 ? var.spanner_nodes * 1000 : null
  num_nodes        = var.spanner_nodes >= 1 ? var.spanner_nodes : null
  depends_on       = [ google_project_service.spanner_services]
  edition          = var.spanner_edition
}

resource "google_spanner_database" "spanner_demo_db" {
  project  = local.project_id
  name     = var.spanner_database_name
  instance = google_spanner_instance.spanner_instance.name
  deletion_protection = false
}

locals {
  spanner_instance_id = split("/", google_spanner_instance.spanner_instance.id)[1] 
  spanner_database_id = split("/", google_spanner_database.spanner_demo_db.id)[1]
}
