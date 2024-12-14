

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
  content = <<-EOT
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

resource null_resource "spanner_env" {
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