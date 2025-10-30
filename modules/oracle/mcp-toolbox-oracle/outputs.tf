output "service_url" {
  description = "The URL of the MCP toolbox."
  value       = module.mcp_toolbox.service_url
}

output "service_account_email" {
  description = "The email of the service account used by the MCP toolbox."
  value       = module.mcp_toolbox.service_account_email
}

output "service_name" {
  description = "The name of the MCP toolbox service."
  value       = module.mcp_toolbox.service_name
}
