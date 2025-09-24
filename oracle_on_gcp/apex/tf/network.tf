# Create VPC
resource "google_compute_network" "oracle" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  depends_on = [ time_sleep.wait_for_api ]
}

# Create subnet
resource "google_compute_subnetwork" "oracle" {
  name                     = "${var.vpc_name}-${var.region}"
  network                  = google_compute_network.oracle.id
  region                   = var.region
  ip_cidr_range            = var.subnet_cidr_range
  private_ip_google_access = true
}

# Create firewall rule for IAP
resource "google_compute_firewall" "oracle_allow_iap" {
  name          = "${var.vpc_name}-allow-iap"
  network       = google_compute_network.oracle.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "TCP"
  }
}

# Create a NAT gateway to allow outbound internet access for private VMs
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.oracle.name
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_vpc_access_connector" "serverless" {
  name          = "serverless-connector"
  region        = var.region
  ip_cidr_range = var.vpc_connector_cidr_range
  network       = google_compute_network.oracle.name
  depends_on = [google_project_service.api["vpcaccess.googleapis.com"]]
}

output "network_name" {
  value = google_compute_network.oracle.name
}