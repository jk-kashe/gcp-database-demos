output "instance" {
  description = "The created GCE instance."
  value       = google_compute_instance.database-clientvm
}

output "clientvm_name" {
  description = "The name of the client VM."
  value       = google_compute_instance.database-clientvm.name
}

output "wait_for_database_clientvm_boot_id" {
  description = "The ID of the time_sleep resource for client VM boot."
  value       = time_sleep.wait_for_database_clientvm_boot.id
}
