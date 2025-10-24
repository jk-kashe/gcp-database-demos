output "service_url" {
  description = "The URL of the MCP toolbox."
  value       = google_cloud_run_v2_service.mcp_toolbox.uri
}

output "service_account_email" {
  description = "The email of the service account used by the MCP toolbox."
  value       = google_service_account.mcp_toolbox_identity.email
}
