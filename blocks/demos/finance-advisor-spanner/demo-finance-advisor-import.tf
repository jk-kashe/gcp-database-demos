resource "null_resource" "demo_finance_advisor_data_import" {
  depends_on = [google_project_iam_member.spanner_dataflow_import_sa_roles]

  provisioner "local-exec" {
    command = <<EOT
    gcloud dataflow jobs run spanner-finadvisor-import \
    --gcs-location gs://dataflow-templates-europe-west1/latest/GCS_Avro_to_Cloud_Spanner \
    --region ${var.region} \
    --network ${google_compute_network.demo_network.name} \
    --parameters \
instanceId=${local.spanner_instance_id},\
databaseId=${local.spanner_database_id},\
inputDir=gs://github-repo/generative-ai/sample-apps/finance-advisor-spanner/spanner-fts-mf-data-export
    EOT
  }
}