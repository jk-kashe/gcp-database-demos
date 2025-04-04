# Depends on:
# landing_zone.tf (for project, network, clientvm base)
# cloudsql.tf (for db instance)

# Execute Cymbal Air DB creation/setup script (vector extension)
resource "null_resource" "cymbal_air_demo_exec_db_script" {
  depends_on = [
    null_resource.db_cloudsql_setup # Depends on the general DB setup now
  ]

  triggers = {
    # Re-run if connection details or script changes
    db_ip         = google_sql_database_instance.primary.private_ip_address
    db_password   = var.db_password
    clientvm_name = var.clientvm-name
    project_id    = local.project_id
    region        = var.region
    zone          = var.zone
    sql_script    = file("files/demo-cymbal-air-create-db.sql")
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Copying Cymbal Air DB create script..."
      gcloud compute scp files/demo-cymbal-air-create-db.sql ${self.triggers.clientvm_name}:~/ \
      --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id}

      echo "Running Cymbal Air DB create script..."
      gcloud compute ssh ${self.triggers.clientvm_name} --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id} \
      --command='source pgauth.env && psql -f ~/demo-cymbal-air-create-db.sql'
    EOT
    environment = {
      PGPASSWORD = self.triggers.db_password
    }
  }
}
