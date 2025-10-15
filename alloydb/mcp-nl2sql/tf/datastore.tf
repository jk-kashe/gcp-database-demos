module "discovery_datastore" {
  source = "../../../modules/discovery-datastore"

  project_id                 = module.landing_zone.project_id
  location                   = var.region
  instance_path              = module.alloydb.primary_instance_name
  database_name              = "pagila"
  database_user_name         = "agent"
  database_user_password     = random_password.agent_password.result
  nl_config_id               = "pagila_demo_cfg"
  datastore_id               = var.datastore_id
  project_services_dependency = [module.landing_zone.project_services]
  script_dir                 = "../"
}
