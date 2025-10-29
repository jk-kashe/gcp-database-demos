terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
    }
  }
}

locals {
  tools_yaml = <<-EOT
    sources:
      my-oracle-source:
        kind: oracle
        host: ${var.oracle_host}
        port: ${var.oracle_port}
        user: ${var.oracle_user}
        password: ${var.oracle_password}
        serviceName: ${var.oracle_service}

    tools:
      execute-ad-hoc-oracle-sql:
        kind: oracle-execute-sql
        source: my-oracle-source
        description: "Executes an arbitrary SQL statement against the Oracle database."

      schema-list-tables:
        kind: oracle-sql
        source: my-oracle-source
        description: "Lists  all tables in a given Oracle schema"
        statement: |
            SELECT table_name FROM ALL_TAB_COLUMNS where owner = :1
        parameters:
          - name: schema_name
            type: string
            description: "The name of the Oracle schema to inspect - case sensitive (all caps by default)."

      schema-list-columns:
        kind: oracle-sql
        source: my-oracle-source
        description: "Lists all columns for all tables in a given Oracle schema"
        statement: |
            SELECT table_name, column_name, data_type FROM ALL_TAB_COLUMNS where owner = :1
        parameters:
          - name: schema_name
            type: string
            description: "The name of the Oracle schema to inspect - case sensitive (all caps by default)."

      schema-list-fk:
        kind: oracle-sql
        source: my-oracle-source
        description: "Lists all foreign keys for all tables in a given Oracle schema"
        statement: |
            SELECT 
              a.table_name, 
              a.column_name, 
              c.table_name AS referenced_table_name, 
              c.column_name AS referenced_column_name,
              a.constraint_name 
            FROM ALL_CONS_COLUMNS a 
            JOIN ALL_CONSTRAINTS b ON a.owner = b.owner 
                                   AND a.constraint_name = b.constraint_name
            JOIN ALL_CONS_COLUMNS c ON b.owner = c.owner 
                                   AND b.r_constraint_name = c.constraint_name 
            WHERE 
              b.constraint_type = 'R' AND
              a.owner = :1 
            ORDER BY a.table_name, a.constraint_name, a.position
        parameters:
          - name: schema_name
            type: string
            description: "The name of the Oracle schema to inspect - case sensitive (all caps by default)."

    toolsets:
      oracle-tools:
        - execute-ad-hoc-oracle-sql
        - schema-list-tables
        - schema-list-columns
        - schema-list-fk
  EOT
}

resource "time_sleep" "wait_for_oracle" {
  create_duration = "60s"
}

module "mcp_toolbox" {
  source = "../../mcp-toolbox"
  providers = {
    google-beta = google-beta
  }

  project_id         = var.project_id
  region             = var.region
  network_name       = var.network_name
  tools_yaml_content = local.tools_yaml
  service_name                  = var.service_name
  vpc_connector_id            = var.vpc_connector_id
  invoker_users                 = var.invoker_users

  depends_on = [time_sleep.wait_for_oracle]
}
