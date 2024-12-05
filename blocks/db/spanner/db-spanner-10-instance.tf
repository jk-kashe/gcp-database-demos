# Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  config       = "regional-${var.region}" # Adjust if needed
  display_name = "${var.spanner_instance_name}"
  project      = local.project_id
  num_nodes    = 1 # Start with one node and scale as needed
  depends_on   = [ google_project_service.spanner_services]
  edition      = "${var.spanner_edition}"
}

resource "google_spanner_database" "spanner_demo_db" {
  name     = "${var.spanner_database_name}"
  instance = google_spanner_instance.spanner_instance.name
}