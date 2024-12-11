resource "google_storage_bucket" "demo_finance_advisor_import_staging" {
    project = local.project_id

    name = "${local.project_id}-finadvdemo-import-staging"
    location = var.region
    uniform_bucket_level_access = true
    public_access_prevention = "enforced"
    force_destroy = true
}


resource "time_sleep" "demo_finance_advisor_sa_roles" {
  create_duration = "2m"  # Adjust the wait time based on your VM boot time

  depends_on = [google_project_iam_member.spanner_dataflow_import_sa_roles]
}


#for some reason, the job fails first / first few times.
#it seems like a timing issue, but time_sleep alone did not resolve it
#this script runs the job until success - up to 5 times
resource "null_resource" "demo_finance_advisor_data_import" {
  depends_on = [time_sleep.demo_finance_advisor_sa_roles,
                google_project_service.project_services,
                google_compute_network.demo_network]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x ./spanner-import.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      ./spanner-import.sh
    EOT

    # Pass variables to the script
    environment = {
      STAGING_LOCATION   = google_storage_bucket.demo_finance_advisor_import_staging.url
      SERVICE_ACCOUNT_EMAIL = "${local.project_number}-compute@developer.gserviceaccount.com"
      REGION             = var.region
      NETWORK            = google_compute_network.demo_network.name
      INSTANCE_ID        = local.spanner_instance_id
      DATABASE_ID        = local.spanner_database_id
      INPUT_DIR          = "gs://github-repo/generative-ai/sample-apps/finance-advisor-spanner/spanner-fts-mf-data-export"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}