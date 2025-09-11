resource "random_password" "oracle_adb" {
  length      = 16
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "google_oracle_database_autonomous_database" "oracle" {
  deletion_protection = false

  autonomous_database_id = var.oracle_adb_instance_name
  display_name           = var.oracle_adb_instance_name
  location               = var.region
  database               = var.oracle_adb_database_name
  admin_password         = random_password.oracle_adb.result
  network                = google_compute_network.oracle.id
  cidr                   = var.oracle_subnet_cidr_range

  properties {
    compute_count                   = var.oracle_compute_count
    data_storage_size_gb            = var.oracle_data_storage_size
    db_version                      = var.oracle_database_version
    db_workload                     = "OLTP"
    is_auto_scaling_enabled         = "true"
    is_storage_auto_scaling_enabled = "true"
    license_type                    = "LICENSE_INCLUDED"
    backup_retention_period_days    = 1
  }
}

locals {
  oracle_database_url = "oracle+oracledb://admin:${random_password.oracle_adb.result}@${google_oracle_database_autonomous_database.oracle.autonomous_database_id}"
  oracle_profiles     = { for profile in google_oracle_database_autonomous_database.oracle.properties[0].connection_strings[0].profiles : lower(profile.consumer_group) => profile if profile.tls_authentication == "SERVER" }
}

# Secrets
resource "google_secret_manager_secret" "oracle_database_url" {
  depends_on = [time_sleep.wait_for_api]

  secret_id = "${google_oracle_database_autonomous_database.oracle.autonomous_database_id}-database-url"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "oracle_database_url" {
  secret      = google_secret_manager_secret.oracle_database_url.id
  secret_data = local.oracle_database_url
}