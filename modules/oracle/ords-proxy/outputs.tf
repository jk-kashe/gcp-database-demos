output "service_url" {
  description = "The URL of the Cloud Run service."
  value       = module.cr_base.service_url
}

output "service_name" {
  description = "The name of the Cloud Run service."
  value       = module.cr_base.service_name
}
