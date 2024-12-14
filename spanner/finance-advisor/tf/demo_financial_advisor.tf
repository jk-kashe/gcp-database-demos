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
#since dataflow script now waits till completion, this is probably not needed
#but still keeping it here for safety
resource "time_sleep" "demo_finadv_import_spanner" {
  depends_on      = [null_resource.demo_finance_advisor_data_import]
  create_duration = "1m"
}

resource "null_resource" "demo_finadv_schema_ops" {
  depends_on = [time_sleep.demo_finadv_import_spanner]

  provisioner "local-exec" {
    command = <<-EOT
    cd files
    wget https://raw.githubusercontent.com/jk-kashe/generative-ai/refs/heads/fix/demo/gemini/sample-apps/finance-advisor-spanner/Schema-Operations.sql
    sed -i "s/<project-name>/${local.project_id}/g" Schema-Operations.sql
    sed -i "s/<location>/${var.region}/g" Schema-Operations.sql 
    # Extract the UPDATE statements
    sed -n '/UPDATE/,/CREATE SEARCH INDEX/p' Schema-Operations.sql | sed '$d' > updates.sql
    # Extract the CREATE SEARCH INDEX statements
    sed -n '/CREATE SEARCH INDEX/,$p' Schema-Operations.sql > search_indexes.sql
    # Extract the initial statements (before UPDATE)
    head -n $(( $(sed -n '/UPDATE/=' Schema-Operations.sql | head -1) - 1 )) Schema-Operations.sql > initial_statements.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step1" {
  depends_on = [null_resource.demo_finadv_schema_ops]

  provisioner "local-exec" {
    command = <<-EOT
    gcloud spanner databases ddl update ${var.spanner_database_name} \
    --project=${local.project_id} \
    --instance=${google_spanner_instance.spanner_instance.name} \
    --ddl-file=files/initial_statements.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step2" {
  depends_on = [null_resource.demo_finadv_schema_ops_step1]

  provisioner "local-exec" {
    command = <<-EOT
    while IFS= read -r line; do
      gcloud spanner databases execute-sql ${var.spanner_database_name} \
          --project=${local.project_id} \
          --instance=${google_spanner_instance.spanner_instance.name} \
          --sql="$line"
    done < files/updates.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step3" {
  depends_on = [null_resource.demo_finadv_schema_ops_step2]

  provisioner "local-exec" {
    command = "files/create_fa_search_indexes.sh ${var.spanner_database_name} ${local.project_id} ${google_spanner_instance.spanner_instance.name}"
  }
}
resource "google_storage_bucket" "demo_finance_advisor_import_staging" {
  project = local.project_id

  name                        = "${local.project_id}-finadvdemo-import-staging"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
}


resource "time_sleep" "demo_finance_advisor_sa_roles" {
  create_duration = "2m" # Adjust the wait time based on your VM boot time

  depends_on = [google_project_iam_member.spanner_dataflow_import_sa_roles]
}


#for some reason, the job fails first / first few times.
#it seems like a timing issue, but time_sleep alone did not resolve it
#this script runs the job until success - up to 5 times
resource "null_resource" "demo_finance_advisor_data_import" {
  depends_on = [time_sleep.demo_finance_advisor_sa_roles,
    google_project_service.project_services,
    google_project_service.lz_dataflow_service,
  google_compute_network.demo_network]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x files/spanner-import.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/spanner-import.sh
    EOT

    # Pass variables to the script
    environment = {
      STAGING_LOCATION      = google_storage_bucket.demo_finance_advisor_import_staging.url
      SERVICE_ACCOUNT_EMAIL = "${local.project_number}-compute@developer.gserviceaccount.com"
      REGION                = var.region
      NETWORK               = google_compute_network.demo_network.name
      INSTANCE_ID           = local.spanner_instance_id
      DATABASE_ID           = local.spanner_database_id
      INPUT_DIR             = "gs://github-repo/generative-ai/sample-apps/finance-advisor-spanner/spanner-fts-mf-data-export"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}
#Fetch and Configure the demo 
resource "null_resource" "demo_finance_advisor_fetch_and_config" {
  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source spanner.env
      sudo apt-get update
      sudo apt install -y python3.11-venv git
      python3 -m venv .demo_spanner_fin_venv
      source .demo_spanner_fin_venv/bin/activate
      pip install --upgrade pip
      git clone --depth 1 --branch fix/demo https://github.com/jk-kashe/generative-ai'
      
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source spanner.env
      source .demo_spanner_fin_venv/bin/activate
      cp spanner.env generative-ai/gemini/sample-apps/finance-advisor-spanner/.env
      cd generative-ai/gemini/sample-apps/finance-advisor-spanner/
      pip install -r requirements.txt'
    EOT
  }
}

#Build the retrieval service using Cloud Build
resource "null_resource" "demo_finance_advisor_build" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
  null_resource.demo_finance_advisor_fetch_and_config]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='cd ~/generative-ai/gemini/sample-apps/finance-advisor-spanner/
      gcloud builds submit --tag ${var.region}-docker.pkg.dev/${local.project_id
  }/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest .'
    EOT
}
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_deploy" {
  name                = "finance-advisor-service"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  project             = local.project_id
  depends_on          = [null_resource.demo_finance_advisor_build]
  deletion_protection = false
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id
      }/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest"
    }
    service_account = google_service_account.cloudrun_identity.email

    vpc_access {
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project  = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service  = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
