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
  for_each = toset(local.default_compute_sa_roles_expanded)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}



#Create and run Create db script
# resource "null_resource" "cymbal_air_demo_create_db_script" {
#   depends_on = [null_resource.install_postgresql_client]

#   provisioner "local-exec" {
#     command = <<-EOT
#       gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-a --tunnel-through-iap \
#       --project ${local.project_id} \
#       --command='cat <<EOF > ~/demo-cymbal-air-create-db.sql
#       CREATE DATABASE assistantdemo;
#       \c assistantdemo
#       CREATE EXTENSION vector;
#       EOF'
#     EOT
#   }
# }

resource "null_resource" "cymbal_air_demo_exec_db_script" {
  depends_on = [null_resource.alloydb_pgauth,
                null_resource.install_postgresql_client]

  triggers = {
    instance_ip     = "${google_alloydb_instance.primary_instance.ip_address}"
    password        = var.alloydb_password
    region          = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute scp demo-cymbal-air-create-db.sql ${var.clientvm-name}:~/ \
      --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id}

      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      psql -f ~/demo-cymbal-air-create-db.sql'
    EOT
  }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<EOT
  #     gcloud compute ssh ${var.clientvm-name} --zone=${self.triggers.region}-a \
  #     --tunnel-through-iap --command='export PGHOST=${self.triggers.instance_ip}
  #     export PGUSER=postgres
  #     export PGPASSWORD=${self.triggers.password}
  #     psql -c 'DROP DATABASE assistantdemo'
  #   EOT
  # }
}

resource "local_file" "cymbal_air_config" {
  filename = "config.yml"
  content  = templatefile("demo-cymbal-air-config.yml.tftpl", {
    project = local.project_id
    region = var.region
    cluster = google_alloydb_cluster.alloydb_cluster.cluster_id
    instance = google_alloydb_instance.primary_instance.instance_id
    database = "assistantdemo"
    username = "postgres"
    password = var.alloydb_password
  })
}

#Fetch and Configure the demo 
resource "null_resource" "cymbal_air_demo_fetch_and_config" {
  depends_on = [null_resource.cymbal_air_demo_exec_db_script,
                google_project_iam_member.default_compute_sa_roles_expanded]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      sudo apt-get update
      sudo apt install -y python3.11-venv git
      python3 -m venv .venv
      source .venv/bin/activate
      pip install --upgrade pip
      git clone --depth 1 --branch v0.1.0/fix/alloydb  https://github.com/jk-kashe/genai-databases-retrieval-app/'
      
      gcloud compute scp config.yml ${var.clientvm-name}:~/genai-databases-retrieval-app/retrieval_service/ \
      --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id}
      
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      source .venv/bin/activate
      cd genai-databases-retrieval-app/retrieval_service
      sed -i s/PUBLIC/PRIVATE/g datastore/providers/alloydb.py
      cat config.yml
      pip install -r requirements.txt
      python run_database_init.py'
    EOT
  }

  # provisioner "local-exec" {
  #   command = <<EOT
  #     gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-a \
  #     --tunnel-through-iap \
  #     --project ${local.project_id} \
  #     --command='export PGHOST=${google_alloydb_instance.primary_instance.ip_address}
  #     export PGUSER=postgres
  #     export PGPASSWORD=${var.alloydb_password}
  #     sudo apt install -y python3.11-venv git
  #     python3 -m venv .venv
  #     source .venv/bin/activate
  #     pip install --upgrade pip
  #     git clone https://github.com/GoogleCloudPlatform/genai-databases-retrieval-app.git
  #     cd genai-databases-retrieval-app/retrieval_service
  #     cp example-config.yml config.yml
  #     sed -i s/127.0.0.1/$PGHOST/g config.yml
  #     sed -i s/my-password/${var.alloydb_password}/g config.yml
  #     sed -i s/my_database/assistantdemo/g config.yml
  #     sed -i s/my-user/postgres/g config.yml
  #     cat config.yml
  #     pip install -r requirements.txt
  #     python run_database_init.py'
  #   EOT
  # }
}

# Service Account Creation for the cloud run middleware retrieval service 
resource "google_service_account" "retrieval_identity" {
  account_id   = "retrieval-identity"
  display_name = "Retrieval Identity"
  project      = local.project_id
  depends_on   = [ google_project_service.project_services ]
}

# Roles for retrieval identity
locals {
  retrieval_identity_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "retrieval_identity_aiplatform_user" {
  for_each   = toset(local.retrieval_identity_roles)
  role       = each.key
  member     = "serviceAccount:${google_service_account.retrieval_identity.email}"
  project    = local.project_id

  depends_on = [ google_service_account.retrieval_identity,
                 google_project_service.project_services ]
}

# Artifact Registry Repository (If not created previously)
resource "google_artifact_registry_repository" "retrieval_service_repo" {
  depends_on    = [google_project_iam_member.default_compute_sa_roles_expanded,
                   google_project_service.project_services]
  provider      = google-beta
  location      = var.region
  repository_id = "retrieval-service-repo"
  description   = "Artifact Registry repository for the retrieval service"
  format        = "DOCKER"
  project       = local.project_id
}

#it takes a while for the SA roles to be applied
resource "time_sleep" "wait_for_sa_roles_expanded" {
  create_duration = "120s"  

  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}

#Build the retrieval service using Cloud Build
resource "null_resource" "cymbal_air_build_retrieval_service" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
                null_resource.cymbal_air_demo_fetch_and_config]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='cd ~/genai-databases-retrieval-app/retrieval_service
      gcloud builds submit --tag ${var.region}-docker.pkg.dev/${local.project_id
}/${google_artifact_registry_repository.retrieval_service_repo.repository_id}/retrieval-service:latest .'
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "retrieval_service" {
  name                = "retrieval-service"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  project             = local.project_id
  depends_on          = [ null_resource.cymbal_air_build_retrieval_service ]
  deletion_protection = false
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id
}/${google_artifact_registry_repository.retrieval_service_repo.repository_id}/retrieval-service:latest"
    }
    service_account = google_service_account.retrieval_identity.email
    
    vpc_access{
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

  }
}

#Configure Python for Cymbal Air Front-end app
resource "null_resource" "cymbal_air_build_sample_app" {
   depends_on = [null_resource.cymbal_air_demo_fetch_and_config,
                 google_cloud_run_v2_service.retrieval_service]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap --project ${local.project_id} \
      --command='python3 -m venv .venv
      source .venv/bin/activate
      cd ~/genai-databases-retrieval-app/llm_demo
      pip install -r requirements.txt'
    EOT
  }
}

#Configure Cymbal Air Front-end app
resource "null_resource" "cymbal_air_prep_sample_app" {
  depends_on = [google_cloud_run_v2_service.retrieval_service,
                null_resource.cymbal_air_build_sample_app]
  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='touch ~/.profile
      echo "export BASE_URL=\$(gcloud  run services list --filter=\"(retrieval-service)\" --format=\"value(URL)\")" >> ~/.profile'
    EOT
  }
}

#IAP brand & Client
resource "google_project_service" "project_service" {
  project = local.project_id
  service = "iap.googleapis.com"
  depends_on   = [ google_project_service.project_services ]
}

resource "google_iap_brand" "cymbal_air_demo_brand" {
  support_email     = var.demo_app_support_email 
  application_title = "Cymbal Air"
  project = google_project_service.project_service.project
  depends_on   = [ google_project_service.project_services ]
}