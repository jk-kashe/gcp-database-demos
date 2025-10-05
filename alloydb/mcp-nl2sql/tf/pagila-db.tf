resource "null_resource" "pagila_db_setup" {
  triggers = {
    install_dependency = module.alloydb.install_postgresql_client.id
    pgauth_dependency = module.alloydb.create_remote_pgauth.id
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${module.client_vm.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
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