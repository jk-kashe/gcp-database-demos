# Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  config           = var.spanner_config == null ? "regional-${var.region}" : var.spanner_config
  display_name     = var.spanner_instance_name
  project          = local.project_id
  processing_units = var.spanner_nodes < 1 ? var.spanner_nodes * 1000 : null
  num_nodes        = var.spanner_nodes >= 1 ? var.spanner_nodes : null
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
  for_each = toset(local.default_compute_sa_roles_dataflow_import)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot,
  google_project_iam_member.default_compute_sa_roles_expanded] #30-landing-zone-clientvm.tf
}


#Add AlloyDB Viwer to the default compute SA
# locals {
#   default_compute_sa_roles = [
#     "roles/alloydb.viewer",
#     "roles/alloydb.client",
#     "roles/aiplatform.user" # for AlloyDB AI 
#   ]
# }

# resource "google_project_iam_member" "default_compute_sa_alloydb_viewer" {
#   for_each = toset(local.default_compute_sa_roles)
#   project  = local.project_id
#   role     = each.key
#   member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
#   depends_on = [time_sleep.wait_for_database_clientvm_boot]
# }

#Install and config Postgres Client
# resource "null_resource" "install_postgresql_client" {
#   depends_on = [google_project_iam_member.default_compute_sa_alloydb_viewer,
#                 google_alloydb_instance.primary_instance,
#                 time_sleep.wait_for_database_clientvm_boot] 

#   provisioner "local-exec" {
#     command = <<-EOT
#       gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
#       --project ${local.project_id} --command='touch ~/.profile &&
#       sudo apt-get update && sudo apt-get dist-upgrade -y
#       sudo apt install postgresql-client -y &&
#       sudo apt install zip unzip -y &&
#       echo "export PROJECT_ID=\${local.project_id}" >> ~/.profile &&
#       echo "export REGION=\${var.region}" >> ~/.profile &&
#       echo "export ADBCLUSTER=\${var.alloydb_cluster_name}" >> ~/.profile &&
#       echo "export PGHOST=\$(gcloud alloydb instances describe ${var.alloydb_primary_name} --cluster=\$ADBCLUSTER --region=\$REGION --format=\"value(ipAddress)\")" >> ~/.profile &&
#       echo "export PGUSER=postgres" >> ~/.profile'
#     EOT
#   }
# }

resource "local_file" "alloydb_client_script" {
  filename = "../spanner-client.sh"
  content  = <<-EOT
#!/bin/bash 
gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
--project ${local.project_id} 
  EOT
}

resource "local_sensitive_file" "spanner_env" {
  filename = "spanner.env"
  content = templatefile("templates/db-spanner.env.tftpl", {
    spanner_instance_id = local.spanner_instance_id
    spanner_database_id = local.spanner_database_id
  })
}

resource "null_resource" "spanner_env" {
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
  provisioner "local-exec" {
    command = <<-EOT
  gcloud compute scp ${local_sensitive_file.spanner_env.filename} ${var.clientvm-name}:~/ \
      --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id}
    EOT
  }
}
#Enable APIs
locals {
  spanner_apis_to_enable = [
    "spanner.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "spanner_services" {
  for_each           = toset(local.spanner_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}

