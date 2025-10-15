locals {
  agentspace_apis_to_enable = [
    "dialogflow.googleapis.com",
    "discoveryengine.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}
resource "google_project_service" "agentspace_services" {
  for_each           = toset(local.agentspace_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [var.project_services_dependency]
  project            = var.project_id
}

resource "local_file" "alloydb_datastore_connect" {
  filename = "${var.script_dir}/alloydb-datastore-${var.datastore_id}.sh"
  content = templatefile("${path.module}/templates/alloydb-datastore.sh.tftpl", {
    project_id             = var.project_id
    location               = var.agentspace_location
    instance_path          = var.instance_path
    database_name          = var.database_name
    database_user_name     = var.database_user_name
    database_user_password = var.database_user_password
    nl_config_id           = var.nl_config_id
    datastore_id           = var.datastore_id
  })
}

resource "null_resource" "create_datastore" {
  depends_on = [local_file.alloydb_datastore_connect, google_project_service.agentspace_services]

  provisioner "local-exec" {
    command = "bash ${local_file.alloydb_datastore_connect.filename}"
  }
}
