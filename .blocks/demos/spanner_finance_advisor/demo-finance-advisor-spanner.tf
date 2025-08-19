#Build the retrieval service using Cloud Build
resource "null_resource" "demo_finance_advisor_build" {
  depends_on = [
    time_sleep.wait_for_sa_roles_expanded
  ]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit https://github.com/GoogleCloudPlatform/generative-ai \
        --project=${local.project_id} \
        --git-source-dir=gemini/sample-apps/finance-advisor-spanner \
        --git-source-revision=${var.finance_advisor_commit_id} \
        --tag ${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_deploy" {
  provider = google-beta

  project = local.project_id
  depends_on = [
    null_resource.demo_finance_advisor_build
  ]

  name                = "finance-advisor-service"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  launch_stage        = var.run_iap ? "BETA" : null
  iap_enabled         = var.run_iap

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest"

      env {
        name  = "instance_id"
        value = local.spanner_instance_id
      }

      env {
        name  = "database_id"
        value = local.spanner_database_id
      }
    }

    vpc_access {
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

    service_account = google_service_account.cloudrun_identity.email
  }
}

data "external" "active_account" {
  program = ["/bin/sh", "-c", "gcloud auth list --format json | jq -r '.[] | select(.status == \"ACTIVE\")'"]
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  count = var.run_iap ? 0: 1

  location = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project  = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service  = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service_iam_member" "run_agent" {
  count = var.run_iap ? 1 : 0

  location = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project  = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service  = google_cloud_run_v2_service.demo_finance_advisor_deploy.name
  member   = "serviceAccount:service-${local.project_number}@gcp-sa-iap.iam.gserviceaccount.com"
  role     = "roles/run.invoker"
}

resource "google_iap_web_cloud_run_service_iam_member" "run_user" {
  count = var.run_iap ? 1 : 0

  location               = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project                = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  cloud_run_service_name = google_cloud_run_v2_service.demo_finance_advisor_deploy.name
  member                 = "user:${data.external.active_account.result.account}"
  role                   = "roles/iap.httpsResourceAccessor"
}