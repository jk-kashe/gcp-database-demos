#since dataflow script now waits till completion, this is probably not needed
#but still keeping it here for safety
resource "time_sleep" "demo_finadv_import_spanner" {
  depends_on = [null_resource.demo_finance_advisor_data_import]
  create_duration = "1m"
}

resource "null_resource" "demo_finadv_schema_ops" {
    depends_on = [time_sleep.demo_finadv_import_spanner]

  provisioner "local-exec" {
    command = <<-EOT
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
    --ddl-file=initial_statements.sql
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
    done < updates.sql
    EOT
  }    
}

resource "null_resource" "demo_finadv_schema_ops_step3" {
    depends_on = [null_resource.demo_finadv_schema_ops_step2]

  provisioner "local-exec" {
    command = "./create_fa_search_indexes.sh ${var.spanner_database_name} ${local.project_id} ${google_spanner_instance.spanner_instance.name}"
   }    
}