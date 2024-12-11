# Network Resources
resource "google_compute_network" "demo_network" {
  name                    = "demo-network"
  auto_create_subnetworks = true 
  depends_on              = [google_project_service.project_services]
  project            = local.project_id

}

# Get the automatically created subnet in config region
data "google_compute_subnetwork" "auto_subnet" {
  name    = "default" # The default name used for auto-created subnets
  region  = var.region
  project = local.project_id
}

# Enable Private Google Access on the subnet
resource "google_compute_subnetwork" "subnet_with_private_access" {
  name                     = data.google_compute_subnetwork.auto_subnet.name
  region                   = var.region
  network                  = google_compute_network.demo_network.id
  private_ip_google_access = true
  project = local.project_id
  # ip_cidr_range            = data.google_compute_subnetwork.auto_subnet.ip_cidr_range # this does not need to be changed
  depends_on = [
    data.google_compute_subnetwork.auto_subnet
  ]
}

resource "google_compute_global_address" "psa_range" {
  name          = "psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.demo_network.id # Or your custom network
  project       = local.project_id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.demo_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name          = "allow-iap-ssh"
  network       = google_compute_network.demo_network.id
  direction     = "INGRESS"
  project       = local.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Create a NAT gateway
resource "google_compute_router" "nat-router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.demo_network.name
  project = local.project_id
}

resource "google_compute_router_nat" "nat-config" {
  name                               = "nat-config"
  router                             = google_compute_router.nat-router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = local.project_id
}
