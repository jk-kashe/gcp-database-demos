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
locals {
  demo_finadv_repo_raw_path = var.finance_advisor_commit_id == "main" ? "refs/heads/main" : var.finance_advisor_commit_id
}

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
    wget https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/${local.demo_finadv_repo_raw_path}/gemini/sample-apps/finance-advisor-spanner/Schema-Operations.sql
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
    # Make the script executable
    command = "chmod +x files/update-spanner-ddl.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/update-spanner-ddl.sh
    EOT

    # Pass variables to the script
    environment = {
      SPANNER_INSTANCE = local.spanner_instance_id
      SPANNER_DATABASE = local.spanner_database_id
      DDL_FILE         = "${path.module}/files/initial_statements.sql"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "demo_finadv_schema_ops_step2" {
  depends_on = [null_resource.demo_finadv_schema_ops_step1]

  provisioner "local-exec" {
    command = <<-EOT
    while IFS= read -r line; do
      gcloud spanner databases execute-sql ${local.spanner_database_id} \
          --project=${local.project_id} \
          --instance=${local.spanner_instance_id} \
          --sql="$line"
    done < files/updates.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step3" {
  depends_on = [null_resource.demo_finadv_schema_ops_step2]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x files/update-spanner-ddl.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/update-spanner-ddl.sh
    EOT

    # Pass variables to the script
    environment = {
      SPANNER_INSTANCE = local.spanner_instance_id
      SPANNER_DATABASE = local.spanner_database_id
      DDL_FILE         = "${path.module}/files/search_indexes.sql"
    }

    interpreter = ["/bin/bash", "-c"]
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
#Build the retrieval service using Cloud Build
resource "null_resource" "demo_finance_advisor_build" {
  depends_on = [
    time_sleep.wait_for_sa_roles_expanded
  ]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit https://github.com/GoogleCloudPlatform/generative-ai \
        --project=${local.project_id} \
        --git-source-dir=gemini/sample-apps/finance-advisor-spanner \
        --git-source-revision=${var.finance_advisor_commit_id} \
        --tag ${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_deploy" {
  project = local.project_id
  depends_on = [
    null_resource.demo_finance_advisor_build
  ]

  name                = "finance-advisor-service"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest"

      env {
        name  = "instance_id"
        value = local.spanner_instance_id
      }

      env {
        name  = "database_id"
        value = local.spanner_database_id
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

    service_account = google_service_account.cloudrun_identity.email
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project  = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service  = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
