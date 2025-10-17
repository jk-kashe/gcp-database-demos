output "apex_url" {
  value = module.cloud_run_ords.apex_url
}

output "apex_admin_password" {
  value       = module.oracle_free.apex_admin_password
  description = "The password for the APEX ADMIN user."
  sensitive   = true
}
