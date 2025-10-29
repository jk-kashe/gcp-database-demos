data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_storage_bucket" "ords_config" {
  name                         = "ords-config-${var.project_id}-${random_string.bucket_suffix.result}"
  location                     = var.region
  force_destroy                = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "compute_sa_gcs_access" {
  bucket = google_storage_bucket.ords_config.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "time_sleep" "wait_for_iam_propagation" {
  create_duration = "30s"
  depends_on = [google_storage_bucket_iam_member.compute_sa_gcs_access]
}




module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id         = var.project_id
  billing_account_id      = var.billing_account_id
  region                  = var.region
  zone                    = random_shuffle.zone.result[0]
  provision_vpc_connector = true
  additional_apis         = ["secretmanager.googleapis.com", "cloudbuild.googleapis.com", "servicedirectory.googleapis.com", "dns.googleapis.com"]
}

module "oracle_free" {
  source = "../../../modules/oracle/oracle-free"

  project_id         = module.landing_zone.project_id
  network_name       = module.landing_zone.demo_network.name
  network_id         = module.landing_zone.demo_network.id
  zone               = module.landing_zone.zone
  vm_oracle_password = var.vm_oracle_password
  client_script_path = "../sqlplus.sh"
  gcs_bucket_name    = google_storage_bucket.ords_config.name
  additional_db_users = [
    {
      username = "MCP_DEMO_USER"
      grants   = ["CONNECT", "RESOURCE", "SELECT ANY TABLE", "SELECT ANY DICTIONARY"]
    },
  ]

  depends_on = [time_sleep.wait_for_iam_propagation]
}

# Wait for APIs to be enabled
resource "time_sleep" "wait_for_apis" {
  create_duration = "60s"
  depends_on = [module.landing_zone]
}

# Private DNS zone for the Oracle VM short name
resource "google_dns_managed_zone" "oracle_vm_private_zone" {
  provider    = google-beta
  name        = "${module.oracle_free.instance.name}-zone"
  dns_name    = "${module.oracle_free.instance.name}."
  description = "Private DNS zone for Oracle VM short name resolution"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = module.landing_zone.demo_network.id
    }
  }
  
  depends_on = [time_sleep.wait_for_apis]
}

# A record for the Oracle VM
resource "google_dns_record_set" "oracle_vm_a_record" {
  provider     = google-beta
  name         = google_dns_managed_zone.oracle_vm_private_zone.dns_name
  managed_zone = google_dns_managed_zone.oracle_vm_private_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [module.oracle_free.instance.network_interface[0].network_ip]
}

# Generate the polling script from the template
resource "local_file" "poll_script" {
  filename = "${path.module}/scripts/poll_ords_version.sh"
  content  = templatefile("${path.module}/templates/poll_ords_version.sh.tpl", {
    vm_name     = module.oracle_free.instance.name,
    zone        = module.oracle_free.instance.zone,
    project_id  = module.landing_zone.project_id,
    output_file = ".ords_version.tmp"
  })
}

# Use the generated script to poll the VM and write the version to a local file.
resource "null_resource" "wait_for_ords_version_script" {
  depends_on = [module.oracle_free.instance, local_file.poll_script]

  provisioner "local-exec" {
    command = "chmod +x ${local_file.poll_script.filename} && ${local_file.poll_script.filename}"
  }
}

# Read the ORDS version from the local file created by the polling script.
data "local_file" "ords_version" {
  filename   = ".ords_version.tmp"
  depends_on = [null_resource.wait_for_ords_version_script]
}

data "external" "gcloud_user" {
  program = ["bash", "${path.module}/files/get_user_email.sh"]
}

module "cloud_run_ords" {
  source = "../../../modules/oracle/cloud-run-ords"

  project_id             = module.landing_zone.project_id
  region                 = module.landing_zone.region
  vm_oracle_password     = var.vm_oracle_password
  db_user_password       = module.oracle_free.db_user_password
  oracle_db_ip           = module.oracle_free.instance.network_interface[0].network_ip
  vpc_connector_id       = module.landing_zone.vpc_connector_id
  ords_container_tag     = data.local_file.ords_version.content
  db_instance_dependency = module.oracle_free.startup_script_wait
  gcs_bucket_name        = google_storage_bucket.ords_config.name
  iam_dependency = [
    google_storage_bucket_iam_member.compute_gcs_access,
    google_storage_bucket_iam_member.cloudbuild_gcs_access,
    google_project_iam_member.compute_ar_writer,
    google_project_iam_member.compute_log_writer
  ]

  depends_on = [
    module.oracle_free,
    module.landing_zone,
    google_dns_record_set.oracle_vm_a_record
  ]
}

module "mcp_toolbox_oracle" {
  source = "../../../modules/oracle/mcp-toolbox-oracle"
  providers = {
    google-beta = google-beta
  }

  project_id      = module.landing_zone.project_id
  region          = module.landing_zone.region
  network_name    = module.landing_zone.demo_network.name
  oracle_host     = module.oracle_free.instance.network_interface[0].network_ip
  oracle_user     = "MCP_DEMO_USER"
  oracle_password = module.oracle_free.additional_db_user_passwords["MCP_DEMO_USER"]
  oracle_service  = "FREEPDB1"
  vpc_connector_id = module.landing_zone.vpc_connector_id
  invoker_users    = ["user:${trimspace(data.external.gcloud_user.result.email)}"]

  depends_on = [
    module.oracle_free,
    module.landing_zone,
    google_dns_record_set.oracle_vm_a_record
  ]
}

module "mcp_adk_bridge" {
  source = "../../../modules/mcp-adk-bridge"

  project_id      = module.landing_zone.project_id
  region          = module.landing_zone.region
  mcp_toolbox_url = module.mcp_toolbox_oracle.service_url
  invoker_users   = ["user:${trimspace(data.external.gcloud_user.result.email)}"]

  depends_on = [
    module.mcp_toolbox_oracle
  ]
}

resource "local_file" "credentials" {
  filename = "../apex-credentials.txt"
  content  = <<-EOT
Your APEX and database credentials:

APEX Admin Password: ${module.oracle_free.apex_admin_password}
Database User Password: ${module.oracle_free.db_user_password}
  EOT
}
