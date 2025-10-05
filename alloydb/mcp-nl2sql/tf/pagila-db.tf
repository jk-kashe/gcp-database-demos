resource "null_resource" "pagila_db_setup" {
  depends_on = [module.alloydb-client-vm]

  provisioner "local-exec" {
    command = <<EOT
      echo "Forcing dependency on provisioning ID: ${module.alloydb-client-vm.provisioned.id}" && \
      gcloud compute ssh ${module.alloydb-client-vm.vm_instance.name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
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