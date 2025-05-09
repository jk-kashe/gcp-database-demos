# Depends on:
# 05-landing-zone-existing-project.tf | 05-landing-zone-new-project.tf
# 20-landing-zone-apis.tf
# 30-landing-zone-clientvm.tf


# Service Account Creation for the cloud run middleware retrieval service 
resource "google_service_account" "cloudrun_identity" {
  account_id   = "cloudrun-identity"
  display_name = "CloudRun Identity"
  project      = local.project_id
  depends_on   = [google_project_service.project_services]
}

# Roles for retrieval identity
locals {
  cloudrun_identity_roles = [
    "roles/alloydb.viewer",
    "roles/alloydb.client",
    "roles/aiplatform.user",
    "roles/spanner.databaseUser"
  ]
}

resource "google_project_iam_member" "cloudrun_identity_aiplatform_user" {
  for_each = toset(local.cloudrun_identity_roles)
  role     = each.key
  member   = "serviceAccount:${google_service_account.cloudrun_identity.email}"
  project  = local.project_id

  depends_on = [google_service_account.cloudrun_identity,
  google_project_service.project_services]
}


#it takes a while for the SA roles to be applied
resource "time_sleep" "wait_for_sa_roles_expanded" {
  create_duration = "120s"

  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}


# Artifact Registry Repository (If not created previously)
resource "google_artifact_registry_repository" "demo_service_repo" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
  google_project_service.project_services] #20-landing-zone-apis.tf
  provider      = google-beta
  location      = var.region
  repository_id = "demo-service-repo"
  description   = "Artifact Registry repository for the demo service(s)"
  format        = "DOCKER"
  project       = local.project_id
}


#for public cloud run deployments
#use the commented block aftert this
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# this is an example config for noauth policy
# just copy and change service name
# resource "google_cloud_run_service_iam_policy" "noauth" {
#   location    = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
#   project     = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
#   service     = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

#   policy_data = data.google_iam_policy.noauth.policy_data
# }
# Enable APIs
locals {
  agentspace_apis_to_enable = [
    "dialogflow.googleapis.com"
  ]
}

resource "google_project_service" "agentspace_services" {
  for_each           = toset(local.agentspace_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}


# Create database
resource "null_resource" "alloydb_agentspace_demo_create_db_script" {
  depends_on = [null_resource.install_postgresql_client]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      psql <<EOF 
      CREATE DATABASE assistantdemo;
      \c assistantdemo
      CREATE EXTENSION vector;
      EOF'
    EOT
  }
}

# Populate database
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
      git clone --depth 1 --revision ${var.agentspace_retrieval_service_repo_revision} ${var.agentspace_retrieval_service_repo}
      cd ${element(split("/", var.agentspace_retrieval_service_repo), -1)}/${var.agentspace_retrieval_service_repo_path}
      pip install -r requirements.txt
      DATASTORE_KIND=alloydb-postgres DATASTORE_PROJECT=${local.project_id} DATASTORE_REGION=${var.region} DATASTORE_CLUSTER=${google_alloydb_cluster.alloydb_cluster.cluster_id} DATASTORE_INSTANCE=${google_alloydb_instance.primary_instance.instance_id} DATASTORE_DATABASE=assistantdemo DATASTORE_USER=postgres DATASTORE_PASSWORD=${var.alloydb_password} python run_database_init.py'
    EOT
  }
}


# Build the retrieval service using Cloud Build
resource "null_resource" "cymbal_air_build_retrieval_service" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
  null_resource.cymbal_air_demo_fetch_and_config]

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit ${var.agentspace_retrieval_service_repo} \
        --project=${local.project_id} \
        --git-source-dir=${var.agentspace_retrieval_service_repo_path} \
        --git-source-revision=${var.agentspace_retrieval_service_repo_revision} \
        --tag ${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/retrieval-service:latest
    EOT
  }
}

# Deploy retrieval service to cloud run
resource "google_secret_manager_regional_secret" "alloydb_credentials_username" {
  project   = local.project_id
  secret_id = "alloydb-credentials-username"
  location  = var.region
}

resource "google_secret_manager_regional_secret" "alloydb_credentials_password" {
  project   = local.project_id
  secret_id = "alloydb-credentials-password"
  location  = var.region
}

resource "google_secret_manager_regional_secret_iam_member" "alloydb_credentials_username_retrieval_service" {
  project   = local.project_id
  location  = var.region
  secret_id = google_secret_manager_regional_secret.alloydb_credentials_username.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.cloudrun_identity.member
}

resource "google_secret_manager_regional_secret_iam_member" "alloydb_credentials_password_retrieval_service" {
  project   = local.project_id
  location  = var.region
  secret_id = google_secret_manager_regional_secret.alloydb_credentials_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.cloudrun_identity.member
}

resource "google_secret_manager_regional_secret_version" "alloydb_credentials_username" {
  secret      = google_secret_manager_regional_secret.alloydb_credentials_username.secret_id
  secret_data = "postgres"
}

resource "google_secret_manager_regional_secret_version" "alloydb_credentials_password" {
  secret      = google_secret_manager_regional_secret.alloydb_credentials_password.secret_id
  secret_data = var.alloydb_password
}

resource "google_cloud_run_v2_service" "retrieval_service" {
  name                = "retrieval-service"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  project             = local.project_id
  depends_on          = [null_resource.cymbal_air_build_retrieval_service]
  deletion_protection = false

  template {
    service_account = google_service_account.cloudrun_identity.email

    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/retrieval-service:latest"

      env {
        name  = "HOST"
        value = "0.0.0.0"
      }

      env {
        name  = "DATASTORE_KIND"
        value = "alloydb-postgres"
      }

      env {
        name  = "DATASTORE_PROJECT"
        value = local.project_id
      }

      env {
        name  = "DATASTORE_REGION"
        value = var.region
      }

      env {
        name  = "DATASTORE_CLUSTER"
        value = google_alloydb_cluster.alloydb_cluster.cluster_id
      }

      env {
        name  = "DATASTORE_INSTANCE"
        value = google_alloydb_instance.primary_instance.instance_id
      }

      env {
        name = "DATASTORE_USER"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_regional_secret.alloydb_credentials_username.secret_id
            version = google_secret_manager_regional_secret_version.alloydb_credentials_username.version
          }
        }
      }

      env {
        name = "DATASTORE_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_regional_secret.alloydb_credentials_password.secret_id
            version = google_secret_manager_regional_secret_version.alloydb_credentials_password.version
          }
        }
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

  }
}

resource "google_cloud_run_v2_service_iam_member" "retrieval_service_dialogflow" {
  depends_on = [google_project_service.agentspace_services]

  project  = local.project_id
  location = var.region
  name     = google_cloud_run_v2_service.retrieval_service.name
  role     = "roles/run.invoker"
  member   = "service-${local.project_number}@gcp-sa-dialogflow.iam.gserviceaccount.com"
}
