data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_storage_bucket" "ords_config" {
  name                         = "ords-config-${var.project_id}-${random_string.bucket_suffix.result}"
  location                     = var.region
  force_destroy                = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "compute_sa_gcs_access" {
  bucket = google_storage_bucket.ords_config.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "time_sleep" "wait_for_iam_propagation" {
  create_duration = "30s"
  depends_on = [google_storage_bucket_iam_member.compute_sa_gcs_access]
}




module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id         = var.project_id
  billing_account_id      = var.billing_account_id
  region                  = var.region
  zone                    = random_shuffle.zone.result[0]
  provision_vpc_connector = true
  additional_apis         = ["secretmanager.googleapis.com", "cloudbuild.googleapis.com", "servicedirectory.googleapis.com", "dns.googleapis.com", "discoveryengine.googleapis.com"]
}

module "oracle_free" {
  source = "../../../modules/oracle/oracle-free"

  project_id         = module.landing_zone.project_id
  network_name       = module.landing_zone.demo_network.name
  network_id         = module.landing_zone.demo_network.id
  zone               = module.landing_zone.zone
  vm_oracle_password = var.vm_oracle_password
  client_script_path = "../sqlplus.sh"
  gcs_bucket_name    = google_storage_bucket.ords_config.name
  additional_db_users = [
    {
      username = "MCP_DEMO_USER"
      grants   = ["CONNECT", "RESOURCE", "SELECT ANY TABLE", "SELECT ANY DICTIONARY"]
    },
  ]

  depends_on = [time_sleep.wait_for_iam_propagation]
}

# Wait for APIs to be enabled
resource "time_sleep" "wait_for_apis" {
  create_duration = "60s"
  depends_on = [module.landing_zone]
}

# Private DNS zone for the Oracle VM short name
resource "google_dns_managed_zone" "oracle_vm_private_zone" {
  provider    = google-beta
  name        = "${module.oracle_free.instance.name}-zone"
  dns_name    = "${module.oracle_free.instance.name}."
  description = "Private DNS zone for Oracle VM short name resolution"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = module.landing_zone.demo_network.id
    }
  }
  
  depends_on = [time_sleep.wait_for_apis]
}

# A record for the Oracle VM
resource "google_dns_record_set" "oracle_vm_a_record" {
  provider     = google-beta
  name         = google_dns_managed_zone.oracle_vm_private_zone.dns_name
  managed_zone = google_dns_managed_zone.oracle_vm_private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [module.oracle_free.instance.network_interface[0].network_ip]
}

# Generate the polling script from the template
resource "local_file" "poll_script" {
  filename = "${path.module}/scripts/poll_ords_version.sh"
  content  = templatefile("${path.module}/templates/poll_ords_version.sh.tpl", {
    vm_name     = module.oracle_free.instance.name,
    zone        = module.oracle_free.instance.zone,
    project_id  = module.landing_zone.project_id,
    output_file = ".ords_version.tmp"
  })
}

# Use the generated script to poll the VM and write the version to a local file.
resource "null_resource" "wait_for_ords_version_script" {
  depends_on = [module.oracle_free.instance, local_file.poll_script]

  provisioner "local-exec" {
    command = "chmod +x ${local_file.poll_script.filename} && ${local_file.poll_script.filename}"
  }
}

# Read the ORDS version from the local file created by the polling script.
data "local_file" "ords_version" {
  filename   = ".ords_version.tmp"
  depends_on = [null_resource.wait_for_ords_version_script]
}

# Generate the APEX workspace creation script
resource "local_file" "create_workspace_script" {
  content = templatefile("${path.module}/templates/create_workspace.sql.tpl", {
    apex_workspace  = var.apex_workspace,
    apex_schema     = var.apex_schema,
    apex_user       = var.apex_user,
    oracle_password = var.vm_oracle_password,
    user_email      = trimspace(data.external.gcloud_user.result.email)
  })
  filename = "${path.module}/files/create_workspace.sql"
}

# Execute the APEX workspace creation script
resource "null_resource" "create_apex_workspace" {
  depends_on = [module.oracle_free.startup_script_wait, local_file.create_workspace_script, null_resource.wait_for_ords_version_script]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute scp ${local_file.create_workspace_script.filename} ${module.oracle_free.instance.name}:/tmp/create_workspace.sql --zone ${module.oracle_free.instance.zone} --project ${var.project_id}
      gcloud compute ssh ${module.oracle_free.instance.name} --zone ${module.oracle_free.instance.zone} --project ${var.project_id} --command 'sudo docker cp /tmp/create_workspace.sql oracle-free:/tmp/create_workspace.sql'
      gcloud compute ssh ${module.oracle_free.instance.name} --zone ${module.oracle_free.instance.zone} --project ${var.project_id} --command 'sudo docker exec oracle-free sqlplus sys/${var.vm_oracle_password}@//localhost:1521/FREEPDB1 as sysdba @/tmp/create_workspace.sql'
    EOT
  }
}

data "external" "gcloud_user" {
  program = ["bash", "${path.module}/files/get_user_email.sh"]
}

module "cloud_run_ords" {
  source = "../../../modules/oracle/cloud-run-ords"

  project_id             = module.landing_zone.project_id
  region                 = module.landing_zone.region
  vm_oracle_password     = var.vm_oracle_password
  db_user_password       = module.oracle_free.db_user_password
  oracle_db_ip           = module.oracle_free.instance.network_interface[0].network_ip
  vpc_connector_id       = module.landing_zone.vpc_connector_id
  ords_container_tag     = data.local_file.ords_version.content
  db_instance_dependency = module.oracle_free.startup_script_wait
  gcs_bucket_name        = google_storage_bucket.ords_config.name
  iam_dependency = [
    google_storage_bucket_iam_member.compute_gcs_access,
    google_storage_bucket_iam_member.cloudbuild_gcs_access,
    google_project_iam_member.compute_ar_writer,
    google_project_iam_member.compute_log_writer
  ]

  depends_on = [
    module.oracle_free,
    module.landing_zone,
    google_dns_record_set.oracle_vm_a_record
  ]
}

module "mcp_toolbox_oracle" {
  source = "../../../modules/oracle/mcp-toolbox-oracle"
  providers = {
    google-beta = google-beta
  }

  project_id      = module.landing_zone.project_id
  region          = module.landing_zone.region
  network_name    = module.landing_zone.demo_network.name
  oracle_host     = module.oracle_free.instance.network_interface[0].network_ip
  oracle_user     = "MCP_DEMO_USER"
  oracle_password = module.oracle_free.additional_db_user_passwords["MCP_DEMO_USER"]
  oracle_service  = "FREEPDB1"
  vpc_connector_id = module.landing_zone.vpc_connector_id
  invoker_users    = ["user:${trimspace(data.external.gcloud_user.result.email)}"]

  depends_on = [
    module.oracle_free,
    module.landing_zone,
    google_dns_record_set.oracle_vm_a_record,
    null_resource.wait_for_ords_version_script
  ]
}

module "adk_reasoning_engine" {
  source = "../../../modules/adk-reasoning-engine"

  project_id          = module.landing_zone.project_id
  region              = module.landing_zone.region
  mcp_toolbox_url     = module.mcp_toolbox_oracle.service_url
  staging_bucket_name = "adk-staging-${data.google_project.project.number}"
  agent_display_name  = "Oracle NL2SQL Agent"
  agent_app_name      = "oracle_agent"
  adk_agent_instruction = <<-EOT
  You are an expert Oracle SQL agent. Your primary function is to translate natural language questions into precise and executable Oracle SQL queries.

  When you receive a question, follow these steps:
  1.  **Understand the Schema:** Use the available tools to explore the database schema.
      *   Use `schema-list-tables` to identify the relevant tables.
      *   Use `schema-list-columns` to understand the columns within those tables.
      *   Use `schema-list-fk` to understand the relationships between tables.
  2.  **Construct the Query:**
      *   Write an Oracle-compliant SQL query to answer the user's question.
      *   **Crucially**, you must prepend the schema name to all table names (e.g., `SCHEMA_NAME.TABLE_NAME`). Remember that schema names in Oracle are often case-sensitive and typically in uppercase. Unless otherwise instructed use ${var.apex_schema} for your queries.
  3.  **Execute the Query:**
      *   Use the `execute-ad-hoc-oracle-sql` tool to run the generated query against the target database.
  4.  **Provide the Answer:** Return the result of the SQL query to the user in a clear and understandable format.
  EOT

  depends_on = [module.mcp_toolbox_oracle]
}

resource "google_cloud_run_v2_service_iam_member" "agent_engine_can_invoke_mcp" {
  project  = module.landing_zone.project_id
  location = module.landing_zone.region
  name     = module.mcp_toolbox_oracle.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform-re.iam.gserviceaccount.com"

  depends_on = [module.adk_reasoning_engine]
}

resource "google_project_iam_member" "aiplatform_sa_cloudrun_invoker" {
  project = module.landing_zone.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform-re.iam.gserviceaccount.com"

  depends_on = [module.adk_reasoning_engine]
}

resource "random_string" "gemini_app_id_suffix" {
  length  = 10
  special = false
  upper   = false
  numeric = true
}

locals {
  gemini_app_id          = "gemini-oracle-app-${random_string.gemini_app_id_suffix.result}"
  gemini_app_display_name = "Gemini ❤️  Oracle"
}

resource "null_resource" "create_gemini_enterprise_app" {
  depends_on = [module.adk_reasoning_engine]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Creating Gemini Enterprise app: ${local.gemini_app_display_name} with ID: ${local.gemini_app_id}"
      curl -X POST \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application/json" \
      -H "X-Goog-User-Project: ${module.landing_zone.project_id}" \
      "https://discoveryengine.googleapis.com/v1/projects/${module.landing_zone.project_id}/locations/global/collections/default_collection/engines?engineId=${local.gemini_app_id}" \
      -d '{
        "displayName": "${local.gemini_app_display_name}",
        "dataStoreEntityIds": ["${module.landing_zone.project_id}"],
        "solutionType": "SOLUTION_TYPE_SEARCH",
        "industryVertical": "GENERIC",
        "appType": "APP_TYPE_INTRANET"
      }'
    EOT
  }
}

resource "null_resource" "link_adk_agent_to_gemini_app" {
  depends_on = [null_resource.create_gemini_enterprise_app]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Linking ADK Agent to Gemini Enterprise App"
      curl -X POST \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application/json" \
        -H "X-Goog-User-Project: ${data.google_project.project.number}" \
        "https://discoveryengine.googleapis.com/v1alpha/projects/${data.google_project.project.number}/locations/global/collections/default_collection/engines/${local.gemini_app_id}/assistants/default_assistant/agents" \
        -d '{
            "displayName": "Oracle NL2SQL Agent",
            "description": "Oracle NL2SQL Agent for APEX.",
            "adk_agent_definition": {
              "tool_settings": {
                "tool_description": "Use this tool to query an Oracle database. Provide question in a natural language."
              },
              "provisioned_reasoning_engine": {
                "reasoning_engine": "${module.adk_reasoning_engine.reasoning_engine_resource_name}"
              }
            }
        }'
    EOT
  }
}


resource "local_file" "credentials" {
  filename = "../apex-credentials.txt"
  content  = <<-EOT
Your APEX and database credentials:

APEX Admin Password: ${module.oracle_free.apex_admin_password}
Database User Password: ${module.oracle_free.db_user_password}
  EOT
}
