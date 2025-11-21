output "project_id" {
  value = module.landing_zone.project_id
}

output "autonomous_database_id" {
  value = module.autonomous_db.autonomous_database_id
}

output "database_url_secret_id" {
  value = module.autonomous_db.database_url_secret_id
}
