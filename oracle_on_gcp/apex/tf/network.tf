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

output "network_name" {
  value = google_compute_network.oracle.name
}