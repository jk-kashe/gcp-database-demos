output "oracle_adb_username" {
  value = "admin"
}

output "oracle_adb_password" {
  value     = random_password.oracle_adb.result
  sensitive = true
}

output "coffee_url" {
  value = google_cloud_run_v2_service.coffee.uri
}