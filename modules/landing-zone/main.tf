# Network Resources
resource "google_compute_network" "demo_network" {
  name                    = "demo-network"
  auto_create_subnetworks = true
  depends_on              = [google_project_service.project_services]
  project                 = local.project_id
}

data "google_compute_subnetwork" "demo_subnetwork" {
  name    = google_compute_network.demo_network.name
  project = local.project_id
  region  = var.region
}

# Enable PGA
resource "null_resource" "demo_network_pga" {
  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute networks subnets update ${google_compute_network.demo_network.name} \
        --project=${local.project_id} \
        --region=${var.region} \
        --enable-private-ip-google-access
    EOT
  }
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
  name      = "allow-iap-ssh"
  network   = google_compute_network.demo_network.id
  direction = "INGRESS"
  project   = local.project_id

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
  depends_on = [google_compute_firewall.allow_iap_ssh]
}

resource "google_compute_router_nat" "nat-config" {
  name                               = "nat-config"
  router                             = google_compute_router.nat-router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = local.project_id
}

#Use EXISTING project
#----------------------------------------------------------
resource "null_resource" "enable_service_usage_api_pre_proj" {
  count = var.create_new_project ? 0 : 1
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com --project ${var.demo_project_id}"
  }
}

resource "google_project_service" "project_rm_api" {
  count              = var.create_new_project ? 0 : 1
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api_pre_proj]
  project            = var.demo_project_id
}

data "google_project" "project_check" {
  count      = var.create_new_project ? 0 : 1
  project_id = var.demo_project_id
  depends_on = [google_project_service.project_rm_api]
}


#Use NEW project
#----------------------------------------------------------
#enable cloud billing api on the project running tf from
resource "null_resource" "enable_cloud_billing_api" {
  count = var.create_new_project ? 1 : 0

  provisioner "local-exec" {
    command = "gcloud services enable cloudbilling.googleapis.com"
  }
}

#Create Project
resource "random_id" "unique_project_suffix" {
  count       = var.create_new_project ? 1 : 0
  byte_length = 3
}

#project provider seems to set org_id, but since config doesn't
#that makes project get re-created on every run
#with this, we read org_id _from the project used to create environment_
#once so there are no issues on subsequential runs
data "external" "org_id" {
  count = var.create_new_project ? 1 : 0

  program = [
    "bash",
    "-c",
    <<EOT
      org_id=$(gcloud projects describe $(gcloud config get-value project) \
      --format='value(parent.id)')
      
      echo '{"org_id": "'"$org_id"'"}'
    EOT
  ]
}

resource "google_project" "demo-project" {
  count           = var.create_new_project ? 1 : 0
  name            = "${var.demo_project_id}-${random_id.unique_project_suffix[0].hex}"
  project_id      = "${var.demo_project_id}-${random_id.unique_project_suffix[0].hex}"
  org_id          = data.external.org_id[0].result.org_id
  billing_account = var.billing_account_id
  depends_on      = [null_resource.enable_cloud_billing_api]
}

locals {
  project_id     = var.create_new_project ? google_project.demo-project[0].project_id : data.google_project.project_check[0].project_id
  project_name   = var.create_new_project ? google_project.demo-project[0].name : data.google_project.project_check[0].name
  project_number = var.create_new_project ? google_project.demo-project[0].number : data.google_project.project_check[0].number
}
resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com --project ${local.project_id}"
  }
}

#Enable APIs
locals {
  default_apis = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "serviceusage.googleapis.com"
  ]
  apis_to_enable = toset(concat(local.default_apis, var.additional_apis))
}

resource "google_project_service" "project_services" {
  for_each           = toset(local.apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}