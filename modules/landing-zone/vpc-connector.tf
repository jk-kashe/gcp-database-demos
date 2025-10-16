resource "google_vpc_access_connector" "connector" {
  count         = var.provision_vpc_connector ? 1 : 0
  name          = "vpc-connector"
  project       = local.project_id
  region        = var.region
  network       = google_compute_network.demo_network.name
  ip_cidr_range = var.vpc_connector_ip_cidr_range
  min_throughput = var.vpc_connector_min_throughput
  max_throughput = var.vpc_connector_max_throughput

  depends_on = [
    google_project_service.project_services["vpcaccess.googleapis.com"]
  ]
}
