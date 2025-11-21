module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id    = var.project_id
  billing_account_id = var.billing_account_id
  region             = var.region
  zone               = var.zone
  create_new_project = var.create_new_project
  provision_vpc_connector = true # Required for Cloud Run to access private ADB
  
  # Enable APIs required for Oracle Autonomous Database
  additional_apis = [
    "compute.googleapis.com",
    "oracledatabase.googleapis.com",
    "secretmanager.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

module "autonomous_db" {
  source = "../../../modules/oracle/autonomous_at_gcp"

  project_id               = module.landing_zone.project_id
  project_number           = module.landing_zone.project_number
  region                   = var.region
  zone                     = var.zone
  network_id               = module.landing_zone.demo_network.id
  oracle_adb_instance_name = var.oracle_adb_instance_name
  oracle_adb_database_name = var.oracle_adb_database_name
  admin_password           = var.admin_password
  client_script_path       = "${path.module}/../sqlplus.sh"
  
  depends_on = [module.landing_zone]
}

data "external" "gcloud_user" {
  program = ["bash", "-c", "echo \"{\"email\": \"$(gcloud auth list --format='value(account)' | head -n 1)\"}\" "]
}

module "ords_proxy" {
  source = "../../../modules/oracle/ords-proxy"

  project_id       = module.landing_zone.project_id
  region           = var.region
  ords_uri         = module.autonomous_db.ords_uri
  vpc_connector_id = module.landing_zone.vpc_connector_id
  invoker_users    = ["user:${data.external.gcloud_user.result.email}"]
  use_iap          = true

  depends_on = [module.autonomous_db]
}
