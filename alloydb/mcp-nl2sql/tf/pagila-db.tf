resource "random_password" "agent_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "local_file" "create_agent_user_sql" {
  content = templatefile("${path.module}/templates/create-agent-user.sql.tpl", {
    agent_password = random_password.agent_password.result
  })
  filename = "${path.module}/files/create-agent-user-generated.sql"
}

resource "null_resource" "pagila_db_setup" {
  depends_on = [module.alloydb-client-vm]

  provisioner "local-exec" {
    command = <<EOT
      echo "Forcing dependency on provisioning ID: ${module.alloydb-client-vm.provisioned.id}" && \
      gcloud compute scp ${path.module}/files/nl2sql-setup.sql ${module.alloydb-client-vm.vm_instance.name}:/tmp/nl2sql-setup.sql --zone=${var.region}-${var.zone} --tunnel-through-iap --project=${module.landing_zone.project_id} && \
      gcloud compute scp ${local_file.create_agent_user_sql.filename} ${module.alloydb-client-vm.vm_instance.name}:/tmp/create-agent-user.sql --zone=${var.region}-${var.zone} --tunnel-through-iap --project=${module.landing_zone.project_id} && \
      gcloud compute scp ${path.module}/files/pagila-update-dates.sql ${module.alloydb-client-vm.vm_instance.name}:/tmp/pagila-update-dates.sql --zone=${var.region}-${var.zone} --tunnel-through-iap --project=${module.landing_zone.project_id} && \
      gcloud compute ssh ${module.alloydb-client-vm.vm_instance.name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${module.landing_zone.project_id} \
      --command='
        git clone https://github.com/devrimgunduz/pagila.git && \
        source pgauth.env && \
        createdb pagila && \
        psql -d pagila -f pagila/pagila-schema.sql && \
        psql -d pagila -f pagila/pagila-data.sql && \
        psql -d pagila -f /tmp/pagila-update-dates.sql && \
        psql -d pagila -c "REFRESH MATERIALIZED VIEW rental_by_category;" && \
        psql -d pagila -f /tmp/nl2sql-setup.sql && \
        psql -d pagila -f /tmp/create-agent-user.sql
      '
    EOT
  }
}