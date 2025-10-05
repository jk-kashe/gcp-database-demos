module "landing_zone" {
  source = "../../../modules/landing-zone"

  demo_project_id    = var.demo_project_id
  billing_account_id = var.billing_account_id
  region             = var.region
  zone               = var.zone
  create_new_project = var.create_new_project
}

module "client_vm" {
  source = "../../../modules/client-vm"

  project_id                    = module.landing_zone.project_id
  project_number                = module.landing_zone.project_number
  region                        = module.landing_zone.region
  zone                          = module.landing_zone.zone
  network_id                    = module.landing_zone.demo_network.id
  clientvm-name                 = var.clientvm-name
  project_services_dependency = module.landing_zone.project_services
}

module "alloydb" {
  source = "../../../modules/alloydb"

  project_id                        = module.landing_zone.project_id
  project_number                    = module.landing_zone.project_number
  region                            = module.landing_zone.region
  zone                              = module.landing_zone.zone
  network_id                        = module.landing_zone.demo_network.id
  clientvm_name                     = module.client_vm.clientvm_name
  alloydb_password                  = var.alloydb_password
  alloydb_cluster_name              = var.alloydb_cluster_name
  alloydb_primary_name              = var.alloydb_primary_name
  alloydb_primary_cpu_count         = var.alloydb_primary_cpu_count
  alloydb_subscription_type         = var.alloydb_subscription_type
  client_script_path                = "../alloydb-client.sh"
  enable_ai                         = true

  # Dependencies
  enable_service_usage_api_dependency = module.landing_zone.project_services
  private_service_access_dependency   = module.landing_zone.private_service_access
  clientvm_boot_dependency            = module.client_vm.wait_for_database_clientvm_boot_id
}
