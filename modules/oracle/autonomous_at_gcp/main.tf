resource "random_password" "oracle_adb" {
  count       = var.admin_password == null ? 1 : 0
  length      = 16
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

locals {
  admin_password = var.admin_password != null ? var.admin_password : random_password.oracle_adb[0].result
}

resource "google_oracle_database_autonomous_database" "oracle" {
  project             = var.project_id
  deletion_protection = false

  autonomous_database_id = var.oracle_adb_instance_name
  display_name           = var.oracle_adb_instance_name
  location               = var.region
  database               = var.oracle_adb_database_name
  admin_password         = local.admin_password
  network                = var.network_id
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

  lifecycle {
    ignore_changes = [odb_network, odb_subnet, admin_password]
  }
}

locals {
  oracle_database_url = "oracle+oracledb://admin:${local.admin_password}@${google_oracle_database_autonomous_database.oracle.autonomous_database_id}"
  oracle_profiles     = { for profile in google_oracle_database_autonomous_database.oracle.properties[0].connection_strings[0].profiles : lower(profile.consumer_group) => profile if profile.tls_authentication == "SERVER" }
}

# Secrets
resource "google_secret_manager_secret" "oracle_database_url" {
  project   = var.project_id
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

resource "random_password" "additional_db_user_passwords" {
  for_each = { for user in var.additional_db_users : user.username => user }
  length   = 16
  special  = false
}

module "client_vm" {
  count  = var.provision_client_vm ? 1 : 0
  source = "../../oracle-client-vm"

  project_id     = var.project_id
  project_number = var.project_number
  region         = var.region
  zone           = var.zone
  network_id     = var.network_id
  clientvm_name  = "client-${var.oracle_adb_instance_name}"
}

resource "local_file" "sqlplus_client_script" {
  count    = var.client_script_path == null ? 0 : 1
  filename = var.client_script_path
  content  = <<-EOT
#!/bin/bash
# This script connects to the Oracle Autonomous Database via the Client VM.
# It requires gcloud to be authenticated and configured.

gcloud compute ssh ${module.client_vm[0].client_vm_name} --zone=${module.client_vm[0].client_vm_zone} --tunnel-through-iap \
--project ${var.project_id} --command='
  sudo -u oracle bash -c "
    export LD_LIBRARY_PATH=/home/oracle/instantclient/instantclient_23_4
    export PATH=$PATH:/home/oracle/instantclient/instantclient_23_4
    export TNS_ADMIN=/home/oracle/instantclient/instantclient_23_4/network/admin
    
    sqlplus admin/${local.admin_password}@${local.oracle_profiles["high"].value}
  "
'
  EOT
}

resource "null_resource" "make_scripts_executable" {
  count = var.client_script_path == null ? 0 : 1

  triggers = {
    sqlplus_script = local_file.sqlplus_client_script[0].filename
  }

  provisioner "local-exec" {
    command = "chmod +x ${local_file.sqlplus_client_script[0].filename}"
  }
}