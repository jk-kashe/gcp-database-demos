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

    toolsets:
      oracle-tools:
        - execute-ad-hoc-oracle-sql
  EOT
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
  invoker_users                 = var.invoker_users
  vpc_connector_id            = var.vpc_connector_id
  current_user_email          = var.current_user_email
}
