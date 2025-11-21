module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id    = var.project_id
  billing_account_id = var.billing_account_id
  region             = var.region
  zone               = var.zone
  create_new_project = var.create_new_project
  
  # Enable APIs required for Oracle Autonomous Database
  additional_apis = [
    "compute.googleapis.com",
    "oracledatabase.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

module "autonomous_db" {
  source = "../../../modules/oracle/autonomous_at_gcp"

  project_id               = module.landing_zone.project_id
  region                   = var.region
  network_id               = module.landing_zone.demo_network.id
  oracle_adb_instance_name = var.oracle_adb_instance_name
  admin_password           = var.admin_password
  
  depends_on = [module.landing_zone]
}
