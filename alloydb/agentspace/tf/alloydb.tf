#Enable APIs
locals {
  alloydb_apis_to_enable = [
    "alloydb.googleapis.com",
    "aiplatform.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
}

resource "google_project_service" "alloydb_services" {
  for_each           = toset(local.alloydb_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}


# AlloyDB Cluster
resource "google_alloydb_cluster" "alloydb_cluster" {
  cluster_id        = var.alloydb_cluster_name
  location          = var.region
  project           = local.project_id
  subscription_type = var.alloydb_subscription_type

  network_config {
    network = google_compute_network.demo_network.id
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

  depends_on = [google_service_networking_connection.private_service_access]
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
  depends_on = [time_sleep.wait_for_network]
}


#Add AlloyDB Viwer to the default compute SA
locals {
  default_compute_sa_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
    "roles/aiplatform.user" # for AlloyDB AI 
  ]
}

resource "google_project_iam_member" "default_compute_sa_alloydb_viewer" {
  for_each   = toset(local.default_compute_sa_roles)
  project    = local.project_id
  role       = each.key
  member     = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}

#Install and config Postgres Client
resource "null_resource" "install_postgresql_client" {
  depends_on = [google_project_iam_member.default_compute_sa_alloydb_viewer,
    google_alloydb_instance.primary_instance,
  time_sleep.wait_for_database_clientvm_boot]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} --command='touch ~/.profile &&
      sudo apt-get update && sudo apt-get dist-upgrade -y
      sudo apt install postgresql-client -y &&
      sudo apt install zip unzip -y &&
      echo "export PROJECT_ID=\${local.project_id}" >> ~/.profile &&
      echo "export REGION=\${var.region}" >> ~/.profile &&
      echo "export ADBCLUSTER=\${var.alloydb_cluster_name}" >> ~/.profile &&
      echo "export PGHOST=\$(gcloud alloydb instances describe ${var.alloydb_primary_name} --cluster=\$ADBCLUSTER --region=\$REGION --format=\"value(ipAddress)\")" >> ~/.profile &&
      echo "export PGUSER=postgres" >> ~/.profile'
    EOT
  }
}

resource "local_file" "alloydb_client_script" {
  filename = "../alloydb-client.sh"
  content  = <<-EOT
#!/bin/bash 
gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
--project ${local.project_id} 
  EOT
}

resource "local_sensitive_file" "alloydb_pgauth" {
  filename = "files/pgauth.env"
  content = templatefile("templates/db-alloydb-pgauth.env.tftpl", {
    pghost     = google_alloydb_instance.primary_instance.ip_address
    pguser     = "postgres"
    pgpassword = var.alloydb_password
    pgsslmode  = "require"
  })
}

resource "null_resource" "alloydb_pgauth" {
  provisioner "local-exec" {
    command = <<-EOT
  gcloud compute scp ${local_sensitive_file.alloydb_pgauth.filename} ${var.clientvm-name}:~/ \
      --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id}
    EOT
  }
}
locals {
  alloydb_sa_roles = [
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "alloydb_sa_roles" {
  for_each   = toset(local.alloydb_sa_roles)
  project    = local.project_id
  role       = each.key
  member     = "serviceAccount:service-${local.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com"
  depends_on = [google_alloydb_instance.primary_instance]
}

resource "null_resource" "db-alloydb-ai-" {
  depends_on = [null_resource.alloydb_pgauth,
  null_resource.install_postgresql_client]

  triggers = {
    instance_ip = "${google_alloydb_instance.primary_instance.ip_address}"
    password    = var.alloydb_password
    region      = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute scp files/db-alloydb-ai.sql ${var.clientvm-name}:~/ \
      --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id}

      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      psql -f ~/db-alloydb-ai.sql'
    EOT
  }
}
