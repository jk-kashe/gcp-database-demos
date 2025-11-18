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

output "vpc_connector_id" {
  description = "The ID of the VPC connector."
  value       = var.provision_vpc_connector ? google_vpc_access_connector.connector[0].id : null
}

output "demo_subnetwork_cidr" {
  description = "The IP CIDR range of the demo subnetwork."
  value       = data.google_compute_subnetwork.demo_subnetwork.ip_cidr_range
}

output "vpc_connector_range" {
  description = "The IP CIDR range of the VPC connector."
  value       = var.provision_vpc_connector ? google_vpc_access_connector.connector[0].ip_cidr_range : null
}

output "demo_subnetwork_self_link" {
  description = "The self_link of the demo subnetwork."
  value       = data.google_compute_subnetwork.demo_subnetwork.self_link
}
