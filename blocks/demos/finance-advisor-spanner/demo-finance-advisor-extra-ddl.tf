resource "time_sleep" "demo_finadv_import_spanner" {
  depends_on = [null_resource.demo_finance_advisor_data_import]
  create_duration = "15m"
}

resource "null_resource" "demo_finadv_schema_ops" {
    depends_on = [time_sleep.demo_finadv_import_spanner]

  provisioner "local-exec" {
    command = <<-EOT
    wget https://raw.githubusercontent.com/jk-kashe/generative-ai/refs/heads/fix/demo/gemini/sample-apps/finance-advisor-spanner/Schema-Operations.sql
    sed -i "s/<project-name>/${local.project_id}/g" Schema-Operations.sql
    sed -i "s/<location>/${var.region}/g" Schema-Operations.sql 
    gcloud spanner databases ddl update ${var.spanner_database_name} \
    --project=${local.project_id} \
    --instance=${google_spanner_instance.spanner_instance.name} \
    --ddl-file=Schema-Operations.sql
    EOT
  }    
}