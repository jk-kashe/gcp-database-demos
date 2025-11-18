output "service_url" {
  description = "The URL of the MCP toolbox."
  value       = module.cr_base.service_url
}

output "service_account_email" {
  description = "The email of the service account used by the MCP toolbox."
  value       = google_service_account.mcp_toolbox_identity.email
}

output "gemini_config_file_path" {
  description = "The path to the generated Gemini CLI settings file."
  value       = var.generate_gemini_config ? var.gemini_config_path : "Not generated."
}
