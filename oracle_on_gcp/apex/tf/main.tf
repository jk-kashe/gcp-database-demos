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


module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id         = var.project_id
  billing_account_id      = var.billing_account_id
  region                  = var.region
  zone                    = random_shuffle.zone.result[0]
  provision_vpc_connector = true
  additional_apis         = ["secretmanager.googleapis.com"]
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

  depends_on = [module.oracle_free]
}

resource "local_file" "credentials" {
  filename = "../apex-credentials.txt"
  content  = <<-EOT
Your APEX and database credentials:

APEX Admin Password: ${module.oracle_free.apex_admin_password}
Database User Password: ${module.oracle_free.db_user_password}
  EOT
}
