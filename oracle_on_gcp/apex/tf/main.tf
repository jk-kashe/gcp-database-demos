data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id         = var.project_id
  billing_account_id      = var.billing_account_id
  region                  = var.region
  zone                    = random_shuffle.zone.result[0]
  provision_vpc_connector = true
}

module "oracle_free" {
  source = "../../../modules/oracle/oracle-free"

  project_id         = module.landing_zone.project_id
  network_name       = module.landing_zone.demo_network.name
  network_id         = module.landing_zone.demo_network.id
  zone               = module.landing_zone.zone
  vm_oracle_password = var.vm_oracle_password
  client_script_path = "../sqlplus.sh"
}

module "cloud_run_ords" {
  source = "../../../modules/oracle/cloud-run-ords"

  project_id           = module.landing_zone.project_id
  region               = module.landing_zone.region
  vm_oracle_password   = var.vm_oracle_password
  db_user_password     = module.oracle_free.db_user_password
  oracle_db_ip         = module.oracle_free.instance.network_interface[0].network_ip
  vpc_connector_id     = module.landing_zone.vpc_connector_id
  db_instance_dependency = module.oracle_free.startup_script_wait
  iam_dependency = [
    google_storage_bucket_iam_member.compute_gcs_access,
    google_storage_bucket_iam_member.cloudbuild_gcs_access,
    google_project_iam_member.compute_ar_writer,
    google_project_iam_member.compute_log_writer
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
