locals {
  alloydb_sa_roles = [
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "alloydb_sa_roles" {
  for_each = toset(local.alloydb_sa_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:service-${local.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com"
  depends_on = [google_alloydb_instance.primary_instance]
}

resource "null_resource" "db-alloydb-ai-" {
  depends_on = [null_resource.alloydb_pgauth,
                null_resource.install_postgresql_client]

  triggers = {
    instance_ip     = "${google_alloydb_instance.primary_instance.ip_address}"
    password        = var.alloydb_password
    region          = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute scp db-alloydb-ai.sql ${var.clientvm-name}:~/ \
      --zone=${var.region}-a \
      --tunnel-through-iap \
      --project ${local.project_id}

      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-a \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      psql -f ~/db-alloydb-ai.sql'
    EOT
  }
}