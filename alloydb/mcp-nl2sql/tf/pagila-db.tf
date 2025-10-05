resource "null_resource" "pagila_db_setup" {
  depends_on = [module.alloydb.install_postgresql_client, module.alloydb.create_remote_pgauth]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${module.landing_zone.project_id} \
      --command=' 
        git clone https://github.com/devrimgunduz/pagila.git && \
        source pgauth.env && \
        createdb pagila && \
        psql -d pagila -f pagila/pagila-schema.sql && \
        psql -d pagila -f pagila/pagila-data.sql
      '
    EOT
  }
}