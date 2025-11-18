output "service_url" {
  description = "The URL of the MCP toolbox."
  value       = module.mcp_toolbox.service_url
}

output "service_name" {
  description = "The name of the Cloud Run service for the MCP toolbox."
  value       = var.service_name
}

output "service_account_email" {
  description = "The email of the service account used by the MCP toolbox."
  value       = module.mcp_toolbox.service_account_email
}
