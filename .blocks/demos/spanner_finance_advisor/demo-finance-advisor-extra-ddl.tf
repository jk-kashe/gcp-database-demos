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
    cd files
    wget https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/refs/heads/main/gemini/sample-apps/finance-advisor-spanner/Schema-Operations.sql
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