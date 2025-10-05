output "project_id" {
  description = "The ID of the GCP project."
  value       = local.project_id
}

output "project_number" {
  description = "The number of the GCP project."
  value       = local.project_number
}

output "region" {
  description = "The GCP region."
  value       = var.region
}

output "zone" {
  description = "The GCP zone."
  value       = var.zone
}

output "demo_network" {
  description = "The demo network."
  value       = google_compute_network.demo_network
}

output "project_services" {
    description = "The project services."
    value = google_project_service.project_services
}

output "private_service_access" {
    description = "The private service access connection."
    value = google_service_networking_connection.private_service_access
}
