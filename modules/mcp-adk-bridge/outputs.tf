output "service_url" {
  description = "The URL of the ADK agent service."
  value       = module.cr_base.service_url
}

output "service_account_email" {
  description = "The email of the service account used by the ADK agent."
  value       = local.service_account_email
}