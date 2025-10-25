output "apex_admin_password" {
  value       = random_password.apex_admin_password.result
  sensitive   = true
  description = "The generated password for the APEX ADMIN user."
}

output "db_user_password" {
  value       = random_password.db_user_password.result
  sensitive   = true
  description = "The generated password for the internal database users."
}

output "instance" {
  value = google_compute_instance.oracle_vm
}

output "startup_script_wait" {

  value = time_sleep.wait_for_startup_script.id

}



output "additional_db_user_passwords" {

  value = { for user in var.additional_db_users : user.username => random_password.additional_db_user_passwords[user.username].result }

  sensitive = true

}
