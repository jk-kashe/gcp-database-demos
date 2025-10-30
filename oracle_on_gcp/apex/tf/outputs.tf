output "mcp_toolbox_url" {
  value = module.mcp_toolbox_oracle.service_url
}

output "adk_reasoning_engine_resource_name" {
  description = "The resource name of the deployed ADK Reasoning Engine."
  value       = module.adk_reasoning_engine.reasoning_engine_resource_name
}

output "apex_url" {
  value = module.cloud_run_ords.apex_url
}

output "apex_admin_password" {
  value       = module.oracle_free.apex_admin_password
  description = "The password for the APEX ADMIN user."
  sensitive   = true
}

output "db_user_password" {
  value       = module.oracle_free.db_user_password
  description = "The password for the database user."
  sensitive   = true
}

output "mcp_demo_user_password" {
  value       = module.oracle_free.additional_db_user_passwords["MCP_DEMO_USER"]
  description = "The password for the MCP_DEMO_USER."
  sensitive   = true
}
