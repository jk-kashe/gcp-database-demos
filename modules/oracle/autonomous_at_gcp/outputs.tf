output "autonomous_database_id" {
  description = "The ID of the Autonomous Database."
  value       = google_oracle_database_autonomous_database.oracle.autonomous_database_id
}

output "autonomous_database_name" {
  description = "The name of the Autonomous Database."
  value       = google_oracle_database_autonomous_database.oracle.name
}

output "admin_password" {
  description = "The admin password for the Autonomous Database."
  value       = random_password.oracle_adb.result
  sensitive   = true
}

output "database_url" {
  description = "The connection URL for the Autonomous Database."
  value       = local.oracle_database_url
  sensitive   = true
}

output "database_url_secret_id" {
  description = "The Secret Manager Secret ID containing the database URL."
  value       = google_secret_manager_secret.oracle_database_url.id
}

output "database_url_secret_version" {
  description = "The Secret Manager Secret Version containing the database URL."
  value       = google_secret_manager_secret_version.oracle_database_url.version
}

output "connection_profiles" {
  description = "The connection profiles for the Autonomous Database."
  value       = local.oracle_profiles
}
