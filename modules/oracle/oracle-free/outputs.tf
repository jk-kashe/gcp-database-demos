output "apex_admin_password" {
  value       = random_password.apex_admin_password.result
  description = "The generated password for the APEX ADMIN user."
}

output "db_user_password" {
  value       = random_password.db_user_password.result
  description = "The generated password for the internal database users."
}

output "instance" {
  value = google_compute_instance.oracle_vm
}

output "startup_script_wait" {
  value = time_sleep.wait_for_startup_script.id
}