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
