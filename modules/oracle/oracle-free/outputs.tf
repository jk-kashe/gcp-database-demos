output "apex_admin_password" {
  value       = random_password.apex_admin_password.result
  description = "The generated password for the APEX ADMIN user."
  sensitive   = true
}

output "db_user_password" {
  value       = random_password.db_user_password.result
  description = "The generated password for the internal database users."
  sensitive   = true
}

output "instance" {
  value = google_compute_instance.oracle_vm
}