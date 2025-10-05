
module "bare-client-vm" {
  source = "../bare-client-vm"

  project_id                  = var.project_id
  project_number              = var.project_number
  region                      = var.region
  zone                        = var.zone
  network_id                  = var.network_id
  clientvm-name               = var.clientvm-name
  project_services_dependency = var.project_services_dependency
}

#this is just to make sure we have ssh keys
resource "null_resource" "lz-init-gcloud-ssh" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud compute config-ssh
    EOT
  }

  depends_on = [module.bare-client-vm]
}

resource "time_sleep" "wait_for_database_clientvm_boot" {
  create_duration = "120s" # Adjust the wait time based on your VM boot time

  depends_on = [module.bare-client-vm, null_resource.lz-init-gcloud-ssh]
}

#Add required roles to the default compute SA (used by clientVM and Cloud Build)
locals {
  default_compute_sa_roles_expanded = [
    "roles/cloudbuild.builds.editor",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "default_compute_sa_roles_expanded" {
  for_each   = toset(local.default_compute_sa_roles_expanded)
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}

#Add AlloyDB Viwer to the default compute SA
locals {
  default_compute_sa_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
    "roles/aiplatform.user",
  ]
}

resource "google_project_iam_member" "default_compute_sa_alloydb_viewer" {
  for_each   = toset(local.default_compute_sa_roles)
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}

resource "time_sleep" "wait_for_iam_compute_sa" {
  create_duration = "30s"

  depends_on = [google_project_iam_member.default_compute_sa_alloydb_viewer]
}

#Install and config Postgres Client
resource "null_resource" "install_postgresql_client" {
  depends_on = [
    time_sleep.wait_for_iam_compute_sa,
  var.alloydb_instance_dependency]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${var.project_id} --command='export DEBIAN_FRONTEND=noninteractive &&
      touch ~/.profile &&
      sudo apt-get update && sudo apt-get -y dist-upgrade &&
      sudo apt-get -y install postgresql-client &&
      sudo apt-get -y install zip unzip &&
      sudo apt-get -y install git &&
      echo "export PROJECT_ID=${var.project_id}" >> ~/.profile &&
      echo "export REGION=${var.region}" >> ~/.profile &&
      echo "export ADBCLUSTER=${var.alloydb_cluster_name}" >> ~/.profile &&
      echo "export PGHOST=\'$(gcloud alloydb instances describe ${var.alloydb_primary_name} --cluster=$ADBCLUSTER --region=$REGION --format=\"value(ipAddress)\")\'" >> ~/.profile &&
      echo "export PGUSER=postgres" >> ~/.profile'
    EOT
  }
}

data "template_file" "pgauth_env" {
  template = file("${path.module}/templates/db-alloydb-pgauth.env.tftpl")

  vars = {
    pghost     = var.alloydb_instance_ip
    pguser     = "postgres"
    pgpassword = var.alloydb_password
    pgsslmode  = "require"
  }
}

resource "null_resource" "create_remote_pgauth" {
  depends_on = [
    var.alloydb_instance_dependency
  ]

  triggers = {
    # Re-run if the password or instance IP changes
    password_hash = sha256(var.alloydb_password)
    instance_ip   = var.alloydb_instance_ip
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "${data.template_file.pgauth_env.rendered}" > pgauth.env
      gcloud compute scp pgauth.env ${var.clientvm_name}:~/ --zone=${var.region}-${var.zone} --tunnel-through-iap --project ${var.project_id}
      rm pgauth.env
      gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap --project ${var.project_id} --command='chmod 600 ~/pgauth.env'
    EOT
  }
}

resource "null_resource" "db-alloydb-ai-" {
  count = var.enable_ai ? 1 : 0

  depends_on = [
    null_resource.create_remote_pgauth,
    null_resource.install_postgresql_client
  ]

  triggers = {
    instance_ip = var.alloydb_instance_ip
    password    = var.alloydb_password
    region      = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute scp ${path.module}/files/db-alloydb-ai.sql ${var.clientvm_name}:~/ --zone=${var.region}-${var.zone} --tunnel-through-iap --project ${var.project_id}

      gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${var.project_id} \
      --command='source pgauth.env && \
      psql -f ~/db-alloydb-ai.sql'
    EOT
  }
}

resource "local_file" "alloydb_client_script" {
  filename = var.client_script_path
  content  = <<-EOT
#!/bin/bash
gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
--project ${var.project_id}
  EOT
}
