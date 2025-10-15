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
  source = "../../../../modules/landing-zone"

  project_id = var.project_id
  region     = var.region
  zone       = random_shuffle.zone.result[0]
}

module "oracle_free" {
  source = "../../../../modules/oracle/oracle-free"

  project_id         = module.landing_zone.project_id
  network_name       = module.landing_zone.network_name
  network_id         = module.landing_zone.network_id
  subnetwork_id      = module.landing_zone.subnetwork_id
  zone               = module.landing_zone.zone
  vm_oracle_password = var.vm_oracle_password
}

module "cloud_run_ords" {
  source = "../../../../modules/oracle/cloud-run-ords"

  project_id           = module.landing_zone.project_id
  region               = module.landing_zone.region
  vm_oracle_password   = var.vm_oracle_password
  oracle_db_ip         = module.oracle_free.instance.network_interface[0].network_ip
  vpc_connector_id     = module.landing_zone.vpc_connector_id
  db_instance_dependency = module.oracle_free.instance
  iam_dependency = [
    google_storage_bucket_iam_member.compute_gcs_access,
    google_storage_bucket_iam_member.cloudbuild_gcs_access,
    google_project_iam_member.compute_ar_writer,
    google_project_iam_member.compute_log_writer
  ]
}
