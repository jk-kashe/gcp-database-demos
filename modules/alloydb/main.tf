#Enable APIs
locals {
  base_apis_to_enable = [
    "alloydb.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
  ]
  ai_apis_to_enable = ["aiplatform.googleapis.com"]
  
  alloydb_apis_to_enable = var.enable_ai ? toset(concat(local.base_apis_to_enable, local.ai_apis_to_enable)) : toset(local.base_apis_to_enable)
}

resource "google_project_service" "alloydb_services" {
  for_each           = local.alloydb_apis_to_enable
  service            = each.key
  disable_on_destroy = false
  depends_on         = [var.enable_service_usage_api_dependency]
  project            = var.project_id
}


# AlloyDB Cluster
resource "google_alloydb_cluster" "alloydb_cluster" {
  cluster_id        = var.alloydb_cluster_name
  location          = var.region
  project           = var.project_id
  subscription_type = var.alloydb_subscription_type

  network_config {
    network = var.network_id
  }

  initial_user {
    user     = "postgres"
    password = var.alloydb_password
  }

  depends_on = [google_project_service.alloydb_services]
}
#there were issues with provisioning primary too soon
resource "time_sleep" "wait_for_network" {
  create_duration = "30s"

  depends_on = [var.private_service_access_dependency]
}

# AlloyDB Instance
resource "google_alloydb_instance" "primary_instance" {
  cluster           = google_alloydb_cluster.alloydb_cluster.name
  instance_id       = var.alloydb_primary_name
  instance_type     = "PRIMARY"
  availability_type = "ZONAL"
  machine_config {
    cpu_count = var.alloydb_primary_cpu_count
  }
  database_flags = var.enable_ai ? {
    "alloydb_ai_nl.enabled" = "on"
  } : {}
  depends_on = [time_sleep.wait_for_network]
}


locals {
  ai_alloydb_sa_roles = ["roles/aiplatform.user"]
  alloydb_sa_roles = var.enable_ai ? toset(local.ai_alloydb_sa_roles) : toset([])
}

resource "google_project_iam_member" "alloydb_sa_roles" {
  for_each   = local.alloydb_sa_roles
  project    = var.project_id
  role       = each.key
  member     = "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com"
  depends_on = [google_alloydb_instance.primary_instance]
}

resource "time_sleep" "wait_for_iam_alloydb_sa" {
  create_duration = "30s"

  depends_on = [google_project_iam_member.alloydb_sa_roles]
}
