output "service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.iap_service.uri
}

output "service_name" {
  description = "The name of the service."
  value       = google_cloud_run_v2_service.iap_service.name
}

output "service_id" {
  description = "The full ID of the service."
  value       = google_cloud_run_v2_service.iap_service.id
}
