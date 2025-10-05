#Enable APIs
locals {
  base_apis_to_enable = [
    "alloydb.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
  ai_apis_to_enable = ["aiplatform.googleapis.com"]
  
  alloydb_apis_to_enable = var.enable_ai ? toset(concat(local.base_apis_to_enable, local.ai_apis_to_enable)) : toset(local.base_apis_to_enable)
}

resource "google_project_service" "alloydb_services" {
  for_each           = local.alloydb_apis_to_enable
  service            = each.key
  disable_on_destroy = false
  depends_on         = [var.enable_service_usage_api_dependency]
  project            = var.project_id
}


# AlloyDB Cluster
resource "google_alloydb_cluster" "alloydb_cluster" {
  cluster_id        = var.alloydb_cluster_name
  location          = var.region
  project           = var.project_id
  subscription_type = var.alloydb_subscription_type

  network_config {
    network = var.network_id
  }

  initial_user {
    user     = "postgres"
    password = var.alloydb_password
  }

  depends_on = [google_project_service.alloydb_services]
}
#there were issues with provisioning primary too soon
resource "time_sleep" "wait_for_network" {
  create_duration = "30s"

  depends_on = [var.private_service_access_dependency]
}

# AlloyDB Instance
resource "google_alloydb_instance" "primary_instance" {
  cluster           = google_alloydb_cluster.alloydb_cluster.name
  instance_id       = var.alloydb_primary_name
  instance_type     = "PRIMARY"
  availability_type = "ZONAL"
  machine_config {
    cpu_count = var.alloydb_primary_cpu_count
  }
  database_flags = var.enable_ai ? {
    "alloydb_ai_nl.enabled" = "on"
  } : {}
  depends_on = [time_sleep.wait_for_network]
}


#Add AlloyDB Viwer to the default compute SA
locals {
  base_default_compute_sa_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
  ]
  ai_default_compute_sa_roles = ["roles/aiplatform.user"]

  default_compute_sa_roles = var.enable_ai ? toset(concat(local.base_default_compute_sa_roles, local.ai_default_compute_sa_roles)) : toset(local.base_default_compute_sa_roles)
}

resource "google_project_iam_member" "default_compute_sa_alloydb_viewer" {
  for_each   = local.default_compute_sa_roles
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [var.clientvm_boot_dependency]
}

resource "time_sleep" "wait_for_iam_compute_sa" {
  create_duration = "30s"

  depends_on = [google_project_iam_member.default_compute_sa_alloydb_viewer]
}

#Install and config Postgres Client
resource "null_resource" "install_postgresql_client" {
  depends_on = [time_sleep.wait_for_iam_compute_sa,
    google_alloydb_instance.primary_instance,
  var.clientvm_boot_dependency]

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
      echo "export PGHOST=\$(gcloud alloydb instances describe ${var.alloydb_primary_name} --cluster=\$ADBCLUSTER --region=\$REGION --format=\"value(ipAddress)\")" >> ~/.profile &&
      echo "export PGUSER=postgres" >> ~/.profile'
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

resource "null_resource" "create_remote_pgauth" {
  depends_on = [
    google_alloydb_instance.primary_instance,
    var.clientvm_boot_dependency
  ]

  triggers = {
    # Re-run if the password or instance IP changes
    password_hash = sha256(var.alloydb_password)
    instance_ip   = google_alloydb_instance.primary_instance.ip_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${var.project_id} --command='echo "export PGHOST=${google_alloydb_instance.primary_instance.ip_address}" > ~/pgauth.env && \
      echo "export PGUSER=postgres" >> ~/pgauth.env && \
      echo "export PGPASSWORD=${var.alloydb_password}" >> ~/pgauth.env && \
      echo "export PGSSLMODE=require" >> ~/pgauth.env && \
      chmod 600 ~/pgauth.env'
    EOT
  }
}

locals {
  ai_alloydb_sa_roles = ["roles/aiplatform.user"]
  alloydb_sa_roles = var.enable_ai ? toset(local.ai_alloydb_sa_roles) : toset([])
}

resource "google_project_iam_member" "alloydb_sa_roles" {
  for_each   = local.alloydb_sa_roles
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com"
  depends_on = [google_alloydb_instance.primary_instance]
}

resource "time_sleep" "wait_for_iam_alloydb_sa" {
  create_duration = "30s"

  depends_on = [google_project_iam_member.alloydb_sa_roles]
}

resource "null_resource" "db-alloydb-ai-" {
  count = var.enable_ai ? 1 : 0

  depends_on = [
    null_resource.create_remote_pgauth,
    null_resource.install_postgresql_client,
    time_sleep.wait_for_iam_alloydb_sa
  ]

  triggers = {
    instance_ip = google_alloydb_instance.primary_instance.ip_address
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
