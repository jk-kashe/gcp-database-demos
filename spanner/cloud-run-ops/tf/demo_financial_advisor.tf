# Depends on:
# 05-landing-zone-existing-project.tf | 05-landing-zone-new-project.tf
# 20-landing-zone-apis.tf
# 30-landing-zone-clientvm.tf


# Service Account Creation for the cloud run middleware retrieval service 
resource "google_service_account" "demo_finance_advisor_api" {
  account_id   = "finance-advisor-api"
  display_name = "Finance Advisor API"
  project      = local.project_id
  depends_on   = [google_project_service.project_services]
}

resource "google_service_account" "demo_finance_advisor_ui" {
  account_id   = "finance-advisor-ui"
  display_name = "Finance Advisor UI"
  project      = local.project_id
  depends_on   = [google_project_service.project_services]
}

# IAM roles for Cloud Run service accounts
resource "google_spanner_instance_iam_member" "demo_finance_advisor_api" {
  instance = google_spanner_instance.spanner_instance.name
  role     = "roles/spanner.databaseReader"
  member   = google_service_account.demo_finance_advisor_api.member
}

#it takes a while for the SA roles to be applied
resource "time_sleep" "wait_for_sa_roles_expanded" {
  create_duration = "120s"

  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]
}


# Artifact Registry Repository (If not created previously)
resource "google_artifact_registry_repository" "demo_service_repo" {
  for_each   = toset(var.regions)
  depends_on = [time_sleep.wait_for_sa_roles_expanded, google_project_service.project_services]
  provider   = google-beta

  location               = each.value
  repository_id          = "demo-service-repo"
  description            = "Artifact Registry repository for the demo service(s)"
  format                 = "DOCKER"
  project                = local.project_id
  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state = "UNTAGGED"
    }
  }

  cleanup_policies {
    id     = "keep-latest"
    action = "KEEP"
    condition {
      tag_state    = "TAGGED"
      tag_prefixes = ["latest"]
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      tag_state  = "TAGGED"
      older_than = "1d"
    }
  }
}

#since dataflow script now waits till completion, this is probably not needed
#but still keeping it here for safety
resource "time_sleep" "demo_finadv_import_spanner" {
  depends_on      = [null_resource.demo_finance_advisor_data_import]
  create_duration = "1m"
}

resource "null_resource" "demo_finadv_schema_ops" {
  depends_on = [time_sleep.demo_finadv_import_spanner]

  provisioner "local-exec" {
    command = <<-EOT
    # Set model endpoints
    sed -i "s@<endpoint>@${join(", ", [for region in var.regions : "//aiplatform.googleapis.com/projects/${local.project_id}/locations/${region}/publishers/google/models/text-embedding-005"])}@g" files/Schema-Operations.sql
    # Extract the UPDATE statements
    sed -n '/UPDATE/,/CREATE SEARCH INDEX/p' files/Schema-Operations.sql | sed '$d' > files/updates.sql
    # Extract the CREATE SEARCH INDEX statements
    sed -n '/CREATE SEARCH INDEX/,$p' files/Schema-Operations.sql > files/search_indexes.sql
    # Extract the initial statements (before UPDATE)
    head -n $(( $(sed -n '/UPDATE/=' files/Schema-Operations.sql | head -1) - 1 )) files/Schema-Operations.sql > files/initial_statements.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step1" {
  depends_on = [null_resource.demo_finadv_schema_ops]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x files/update-spanner-ddl.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/update-spanner-ddl.sh
    EOT

    # Pass variables to the script
    environment = {
      SPANNER_INSTANCE = local.spanner_instance_id
      SPANNER_DATABASE = local.spanner_database_id
      DDL_FILE         = "${path.module}/files/initial_statements.sql"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "demo_finadv_schema_ops_step2" {
  depends_on = [null_resource.demo_finadv_schema_ops_step1]

  provisioner "local-exec" {
    command = <<-EOT
    while IFS= read -r line; do
      gcloud spanner databases execute-sql ${local.spanner_database_id} \
          --project=${local.project_id} \
          --instance=${local.spanner_instance_id} \
          --sql="$line"
    done < files/updates.sql
    EOT
  }
}

resource "null_resource" "demo_finadv_schema_ops_step3" {
  depends_on = [null_resource.demo_finadv_schema_ops_step2]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x files/update-spanner-ddl.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/update-spanner-ddl.sh
    EOT

    # Pass variables to the script
    environment = {
      SPANNER_INSTANCE = local.spanner_instance_id
      SPANNER_DATABASE = local.spanner_database_id
      DDL_FILE         = "${path.module}/files/search_indexes.sql"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}
resource "google_storage_bucket" "demo_finance_advisor_import_staging" {
  project = local.project_id

  name                        = "${local.project_id}-finadvdemo-import-staging"
  location                    = var.regions[0]
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
}


resource "time_sleep" "demo_finance_advisor_sa_roles" {
  create_duration = "2m" # Adjust the wait time based on your VM boot time

  depends_on = [google_project_iam_member.spanner_dataflow_import_sa_roles]
}


#for some reason, the job fails first / first few times.
#it seems like a timing issue, but time_sleep alone did not resolve it
#this script runs the job until success - up to 5 times
resource "null_resource" "demo_finance_advisor_data_import" {
  depends_on = [time_sleep.demo_finance_advisor_sa_roles,
    google_project_service.project_services,
    google_project_service.lz_dataflow_service,
  google_compute_network.demo_network]

  provisioner "local-exec" {
    # Make the script executable
    command = "chmod +x files/spanner-import.sh"
    # Use interpreter to pass arguments to the script
    interpreter = ["/bin/bash", "-c"]
  }

  provisioner "local-exec" {
    # Execute the script to submit the job and wait for completion
    command = <<EOT
      files/spanner-import.sh
    EOT

    # Pass variables to the script
    environment = {
      STAGING_LOCATION      = google_storage_bucket.demo_finance_advisor_import_staging.url
      SERVICE_ACCOUNT_EMAIL = "${local.project_number}-compute@developer.gserviceaccount.com"
      REGION                = var.regions[0]
      NETWORK               = google_compute_network.demo_network.name
      INSTANCE_ID           = local.spanner_instance_id
      DATABASE_ID           = local.spanner_database_id
      INPUT_DIR             = "gs://alloydb-vector-demo/spanner/finance-advisor/avro"
    }

    interpreter = ["/bin/bash", "-c"]
  }
}
#Build the retrieval service using Cloud Build
locals {
  demo_service_docker_repo       = { for region in var.regions : region => "${region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo[region].repository_id}" }
  demo_finance_advisor_api_image = { for region in var.regions : region => "${local.demo_service_docker_repo[region]}/finance-advisor-api" }
  demo_finance_advisor_ui_image  = { for region in var.regions : region => "${local.demo_service_docker_repo[region]}/finance-advisor-ui" }
}

resource "random_string" "demo_finance_advisor_api_tag" {
  keepers = {
    dockerfile = filesha256("${path.module}/../api/Dockerfile"),
    cloudbuild = filesha256("${path.module}/templates/cloudbuild.yaml.tftpl")
    regions    = join(", ", sort(var.regions))
  }

  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "local_file" "demo_finance_advisor_api_build" {
  filename = "${path.module}/../api/cloudbuild.yaml"
  content = templatefile("${path.module}/templates/cloudbuild.yaml.tftpl", {
    tags = flatten([for region in var.regions : ["${local.demo_finance_advisor_api_image[region]}:${random_string.demo_finance_advisor_api_tag.result}", "${local.demo_finance_advisor_api_image[region]}:latest"]])
  })
}

resource "null_resource" "demo_finance_advisor_api_build" {
  depends_on = [
    time_sleep.wait_for_sa_roles_expanded,
    google_artifact_registry_repository.demo_service_repo
  ]

  triggers = {
    tag = random_string.demo_finance_advisor_api_tag.result
  }

  # provisioner "local-exec" {
  #   command = <<-EOT
  #     gcloud builds submit ../api \
  #       --project=${local.project_id} \
  #       ${join(" ", [for region in var.regions : "--tag ${local.demo_finance_advisor_api_image[region]}:${random_string.demo_finance_advisor_tag.result} --tag ${local.demo_finance_advisor_api_image[region]}:latest"])}
  #   EOT
  # }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit ../api \
        --project=${local.project_id} \
        --config=../api/cloudbuild.yaml
    EOT
  }
}

resource "random_string" "demo_finance_advisor_ui_tag" {
  keepers = {
    dockerfile = filesha256("${path.module}/../ui/Dockerfile"),
    cloudbuild = filesha256("${path.module}/templates/cloudbuild.yaml.tftpl")
    regions    = join(", ", sort(var.regions))
  }

  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "local_file" "demo_finance_advisor_ui_build" {
  filename = "${path.module}/../ui/cloudbuild.yaml"
  content = templatefile("${path.module}/templates/cloudbuild.yaml.tftpl", {
    tags = flatten([for region in var.regions : ["${local.demo_finance_advisor_ui_image[region]}:${random_string.demo_finance_advisor_ui_tag.result}", "${local.demo_finance_advisor_ui_image[region]}:latest"]])
  })
}

resource "null_resource" "demo_finance_advisor_ui_build" {
  depends_on = [
    time_sleep.wait_for_sa_roles_expanded,
    google_artifact_registry_repository.demo_service_repo
  ]

  triggers = {
    tag = random_string.demo_finance_advisor_ui_tag.result
  }

  # provisioner "local-exec" {
  #   command = <<-EOT
  #     gcloud builds submit ../ui \
  #       --project=${local.project_id} \
  #       ${join(" ", [for region in var.regions : "--tag ${local.demo_finance_advisor_ui_image[region]}:${random_string.demo_finance_advisor_tag.result} --tag ${local.demo_finance_advisor_ui_image[region]}:latest"])}
  #   EOT
  # }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit ../ui \
        --project=${local.project_id} \
        --config=../ui/cloudbuild.yaml
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_api" {
  for_each = toset(var.regions)
  project  = local.project_id
  depends_on = [
    null_resource.demo_finance_advisor_api_build
  ]

  name                = "finance-advisor-api-${each.value}"
  location            = each.value
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    service_account                  = google_service_account.demo_finance_advisor_api.email
    max_instance_request_concurrency = 80

    containers {
      image = "${local.demo_finance_advisor_api_image[each.value]}:${random_string.demo_finance_advisor_api_tag.result}"

      env {
        name  = "SPANNER_INSTANCE_ID"
        value = local.spanner_instance_id
      }

      env {
        name  = "SPANNER_DATABASE_ID"
        value = local.spanner_database_id
      }

      env {
        name  = "WORKERS"
        value = "1"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/health"
        }
      }

      liveness_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/health"
        }
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }
  }
}

resource "google_cloud_run_v2_service" "demo_finance_advisor_ui" {
  for_each = toset(var.regions)
  project  = local.project_id
  depends_on = [
    null_resource.demo_finance_advisor_ui_build
  ]

  name                = "finance-advisor-ui-${each.value}"
  location            = each.value
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${local.demo_finance_advisor_ui_image[each.value]}:${random_string.demo_finance_advisor_ui_tag.result}"

      env {
        name  = "API_BASE_URL"
        value = google_cloud_run_v2_service.demo_finance_advisor_api[each.value].uri
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/_stcore/health"
        }
      }

      liveness_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/_stcore/health"
        }
      }
    }

    service_account = google_service_account.demo_finance_advisor_ui.email
  }
}

resource "google_cloud_run_service_iam_member" "demo_finance_advisor_api" {
  for_each = toset(var.regions)

  project  = google_cloud_run_v2_service.demo_finance_advisor_api[each.value].project
  location = google_cloud_run_v2_service.demo_finance_advisor_api[each.value].location
  service  = google_cloud_run_v2_service.demo_finance_advisor_api[each.value].name
  role     = "roles/run.invoker"
  member   = google_service_account.demo_finance_advisor_ui.member
}

resource "null_resource" "create_iap_sa" {
  depends_on = [google_project_service.project_services]

  provisioner "local-exec" {
    command = "gcloud beta services identity create --service=iap.googleapis.com --project=${local.project_id}"
  }
}

resource "google_cloud_run_service_iam_member" "demo_finance_advisor_ui" {
  depends_on = [null_resource.create_iap_sa]
  for_each   = toset(var.regions)

  project  = google_cloud_run_v2_service.demo_finance_advisor_ui[each.value].project
  location = google_cloud_run_v2_service.demo_finance_advisor_ui[each.value].location
  service  = google_cloud_run_v2_service.demo_finance_advisor_ui[each.value].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${local.project_number}@gcp-sa-iap.iam.gserviceaccount.com"
}

# Load balancer
resource "google_compute_global_address" "demo_finance_advisor" {
  name         = "finance-advisor"
  address_type = "EXTERNAL"
}

resource "google_dns_record_set" "demo_finance_advisor" {
  project = local.dns_project_id

  managed_zone = var.dns_zone_name
  name         = var.demo_hostname
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.demo_finance_advisor.address]
}

resource "google_compute_managed_ssl_certificate" "demo_finance_advisor" {
  name = "demo-finance-advisor"

  managed {
    domains = [var.demo_hostname]
  }
}

resource "google_compute_region_network_endpoint_group" "demo_finance_advisor_ui" {
  for_each = toset(var.regions)

  name                  = "demo-finance-advisor-ui-${each.value}"
  region                = each.value
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.demo_finance_advisor_ui[each.value].name
  }
}

resource "google_compute_backend_service" "demo_finance_advisor_ui" {
  name                  = "demo-finance-advisor-ui"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  iap {
    enabled = true
  }

  dynamic "backend" {
    for_each = toset(var.regions)

    content {
      group = google_compute_region_network_endpoint_group.demo_finance_advisor_ui[backend.value].id
    }
  }
}

resource "google_compute_url_map" "demo_finance_advisor" {
  name            = "demo-finance-advisor"
  default_service = google_compute_backend_service.demo_finance_advisor_ui.id
}

resource "google_compute_target_https_proxy" "demo_finance_advisor" {
  name             = "demo-finance-advisor-https"
  url_map          = google_compute_url_map.demo_finance_advisor.name
  ssl_certificates = [google_compute_managed_ssl_certificate.demo_finance_advisor.id]
}

resource "google_compute_global_forwarding_rule" "demo_finance_advisor" {
  name                  = "demo-finance-advisor"
  ip_address            = google_compute_global_address.demo_finance_advisor.id
  port_range            = "443"
  target                = google_compute_target_https_proxy.demo_finance_advisor.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_iap_web_backend_service_iam_member" "demo_finance_advisor" {
  for_each = var.demo_users

  web_backend_service = google_compute_backend_service.demo_finance_advisor_ui.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "user:${each.value}"
}
# Load test
resource "local_file" "load_test" {
  filename = "${path.module}/k6/loadTest.sh"
  content = templatefile("${path.module}/templates/loadTest.sh.tftpl", {
    base_url = google_cloud_run_v2_service.demo_finance_advisor_api[var.regions[0]].uri
  })
}