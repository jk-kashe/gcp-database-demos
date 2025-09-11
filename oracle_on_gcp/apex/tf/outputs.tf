output "oracle_adb_username" {
  value = "admin"
}

output "oracle_adb_password" {
  value     = random_password.oracle_adb.result
  sensitive = true
}
