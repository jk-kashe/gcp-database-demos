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
    "dialogflow.googleapis.com",
    "discoveryengine.googleapis.com",
    "secretmanager.googleapis.com"
  ]

  agentspace_datastores = toset([
    "airports",
    "amenities",
    "flights",
    "policies",
    "tickets"
  ])
}

resource "google_project_service" "agentspace_services" {
  for_each           = toset(local.agentspace_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}


# Create database
resource "null_resource" "agentspace_alloydb_demo_create_db_script" {
  depends_on = [null_resource.install_postgresql_client]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source pgauth.env
      psql <<EOF 
        CREATE DATABASE assistantdemo;
        \c assistantdemo;
        CREATE EXTENSION vector;
EOF'
    EOT
  }
}

# Populate database
resource "null_resource" "agentspace_alloydb_demo_fetch_and_config" {
  depends_on = [null_resource.agentspace_alloydb_demo_create_db_script,
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
      git clone ${var.agentspace_retrieval_service_repo}
      cd ${reverse(split("/", var.agentspace_retrieval_service_repo))[0]}/${var.agentspace_retrieval_service_repo_path}
      git checkout ${var.agentspace_retrieval_service_repo_revision} 
      pip install -r requirements.txt
      DATASTORE_KIND=alloydb-postgres DATASTORE_PROJECT=${local.project_id} DATASTORE_REGION=${var.region} DATASTORE_CLUSTER=${google_alloydb_cluster.alloydb_cluster.cluster_id} DATASTORE_INSTANCE=${google_alloydb_instance.primary_instance.instance_id} DATASTORE_DATABASE=assistantdemo DATASTORE_IP_TYPE=PRIVATE DATASTORE_USER=postgres DATASTORE_PASSWORD=${var.alloydb_password} python run_database_init.py'
    EOT
  }
}


# Build the retrieval service using Cloud Build
resource "null_resource" "agentspace_alloydb_demo_build_retrieval_service" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
  null_resource.agentspace_alloydb_demo_fetch_and_config]

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
resource "google_secret_manager_secret" "alloydb_credentials_username" {
  depends_on = [google_project_service.agentspace_services]

  project   = local.project_id
  secret_id = "alloydb-credentials-username"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret" "alloydb_credentials_password" {
  depends_on = [google_project_service.agentspace_services]

  project   = local.project_id
  secret_id = "alloydb-credentials-password"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_iam_member" "alloydb_credentials_username_retrieval_service" {
  project   = local.project_id
  secret_id = google_secret_manager_secret.alloydb_credentials_username.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.cloudrun_identity.member
}

resource "google_secret_manager_secret_iam_member" "alloydb_credentials_password_retrieval_service" {
  project   = local.project_id
  secret_id = google_secret_manager_secret.alloydb_credentials_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.cloudrun_identity.member
}

resource "google_secret_manager_secret_version" "alloydb_credentials_username" {
  secret      = google_secret_manager_secret.alloydb_credentials_username.id
  secret_data = "postgres"
}

resource "google_secret_manager_secret_version" "alloydb_credentials_password" {
  secret      = google_secret_manager_secret.alloydb_credentials_password.id
  secret_data = var.alloydb_password
}

resource "google_cloud_run_v2_service" "retrieval_service" {
  name                = "retrieval-service"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  project             = local.project_id
  depends_on          = [null_resource.agentspace_alloydb_demo_build_retrieval_service]
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
        name  = "DATASTORE_DATABASE"
        value = "assistantdemo"
      }

      env {
        name  = "DATASTORE_IP_TYPE"
        value = "PRIVATE"
      }

      env {
        name = "DATASTORE_USER"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.alloydb_credentials_username.secret_id
            version = google_secret_manager_secret_version.alloydb_credentials_username.version
          }
        }
      }

      env {
        name = "DATASTORE_PASSWORD"

        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.alloydb_credentials_password.secret_id
            version = google_secret_manager_secret_version.alloydb_credentials_password.version
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

# resource "google_cloud_run_v2_service_iam_member" "retrieval_service_dialogflow" {
#   depends_on = [google_project_service.agentspace_services]

#   project  = local.project_id
#   location = var.region
#   name     = google_cloud_run_v2_service.retrieval_service.name
#   role     = "roles/run.invoker"
#   member   = "serviceAccount:service-${local.project_number}@gcp-sa-dialogflow.iam.gserviceaccount.com"
# }

# Create data stores
resource "google_discovery_engine_data_store" "demo_agentspace_alloydb" {
  for_each   = local.agentspace_datastores
  depends_on = [google_project_service.agentspace_services]

  location                     = "global"
  data_store_id                = "cymbal-air-${each.value}"
  display_name                 = "Cymbal Air ${each.value}"
  industry_vertical            = "GENERIC"
  content_config               = "NO_CONTENT"
  skip_default_schema_creation = true
}

resource "google_discovery_engine_schema" "demo_agentspace_alloydb" {
  for_each   = local.agentspace_datastores
  depends_on = [google_project_service.agentspace_services]

  data_store_id = google_discovery_engine_data_store.demo_agentspace_alloydb[each.value].data_store_id
  location      = google_discovery_engine_data_store.demo_agentspace_alloydb[each.value].location
  schema_id     = "default_schema"
  json_schema   = file("files/agentspace-${each.value}-schema.json")
}

# Create import script
resource "local_file" "demo_agentspace_alloydb_import" {
  filename = "files/agentspace-import.sh"
  content = templatefile("templates/agentspace-import.sh.tftpl", {
    project  = local.project_id
    location = var.region
    cluster  = google_alloydb_cluster.alloydb_cluster.cluster_id
    database = var.agentspace_alloydb_database_name
  })
}

# Create connect script
resource "local_file" "demo_agentspace_alloydb_connect" {
  filename = "files/agentspace-connect.sh"
  content = templatefile("templates/agentspace-connect.sh.tftpl", {
    PROJECT_ID             = local.project_id
    LOCATION               = var.agentspace_location
    INSTANCE_PATH          = var.agentspace_alloydb_path
    DATABASE_NAME          = var.agentspace_alloydb_database_name
    DATABASE_USER_NAME     = var.agentspace_alloydb_database_user_name
    DATABASE_USER_PASSWORD = var.agentspace_alloydb_database_user_password
    NL_CONFIG_ID           = var.agentspace_alloydb_database_nl_config_id
  })
}

# Create OpenAPI spec
resource "local_file" "demo_agentspace_alloydb_openapi" {
  filename = "files/agentspace-openapi.yaml"
  content = templatefile("templates/agentspace-openapi.yaml.tftpl", {
    url = google_cloud_run_v2_service.retrieval_service.uri
  })
}
