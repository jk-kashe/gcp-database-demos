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

# Use a local script to poll the VM until the ORDS version guest attribute is available.
resource "null_resource" "wait_for_ords_version_script" {
  depends_on = [module.oracle_free.instance]

  provisioner "local-exec" {
    command = <<-EOT
      bash -c '
        COUNTER=0
        MAX_RETRIES=40 # 40 * 60s = 2400s = 40 minutes
        VM_NAME="${module.oracle_free.instance.name}"
        ZONE="${module.oracle_free.instance.zone}"
        PROJECT_ID="${module.landing_zone.project_id}"

        while true; do
          VALUE=$(gcloud compute instances get-guest-attributes ${VM_NAME} --query-path="ords/version" --zone="${ZONE}" --project="${PROJECT_ID}" 2>/dev/null)
          if [[ -n "$VALUE" ]]; then
            echo "Found ORDS version: $VALUE"
            break
          fi

          ((COUNTER++))
          if ((COUNTER > MAX_RETRIES)); then
            echo "Error: Timed out waiting for ORDS version attribute on VM ${VM_NAME}."
            exit 1
          fi

          echo "Waiting for ORDS version attribute... (Attempt ${COUNTER}/${MAX_RETRIES})"
          sleep 60
        done
      '
    EOT
  }
}

# Read the ORDS version reported by the VM from its guest attributes.
data "google_compute_instance_guest_attributes" "ords_version" {
  project = module.landing_zone.project_id
  zone    = module.landing_zone.zone
  name    = module.oracle_free.instance.name
  query_path = "ords/version"

  depends_on = [null_resource.wait_for_ords_version_script]
}

module "cloud_run_ords" {
  source = "../../../modules/oracle/cloud-run-ords"

  project_id           = module.landing_zone.project_id
  region               = module.landing_zone.region
  vm_oracle_password   = var.vm_oracle_password
  db_user_password     = module.oracle_free.db_user_password
  oracle_db_ip         = module.oracle_free.instance.network_interface[0].network_ip
  vpc_connector_id     = module.landing_zone.vpc_connector_id
  ords_container_tag   = data.google_compute_instance_guest_attributes.ords_version.query_value
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
