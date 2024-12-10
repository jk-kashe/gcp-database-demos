resource "google_storage_bucket" "demo_finance_advisor_import_staging" {
    project = local.project_id

    name = "${local.project_id}-finadvdemo-import-staging"
    location = var.region
    uniform_bucket_level_access = true
    public_access_prevention = "enforced"
    force_destroy = true
}


resource "time_sleep" "demo_finance_advisor_sa_roles" {
  create_duration = "5m"  # Adjust the wait time based on your VM boot time

  depends_on = [google_project_iam_member.spanner_dataflow_import_sa_roles]
}

#this seems to need a bit of a time to go through successfully
resource "null_resource" "demo_finance_advisor_data_import" {
  depends_on = [time_sleep.demo_finance_advisor_sa_roles]

  provisioner "local-exec" {
    command = <<EOT
    gcloud dataflow jobs run spanner-finadvisor-import \
    --gcs-location gs://dataflow-templates-${var.region}/latest/GCS_Avro_to_Cloud_Spanner \
    --staging-location=${google_storage_bucket.demo_finance_advisor_import_staging.url} \
    --service-account-email=${local.project_number}-compute@developer.gserviceaccount.com \
    --region ${var.region} \
    --network ${google_compute_network.demo_network.name} \
    --parameters \
instanceId=${local.spanner_instance_id},\
databaseId=${local.spanner_database_id},\
inputDir=gs://github-repo/generative-ai/sample-apps/finance-advisor-spanner/spanner-fts-mf-data-export
    EOT
  }
}