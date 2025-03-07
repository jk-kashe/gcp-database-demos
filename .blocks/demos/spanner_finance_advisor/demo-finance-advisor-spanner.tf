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
        --git-source-revision=main \
        --tag ${var.region}-docker.pkg.dev/${local.project_id}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_deploy" {
  project = local.project_id
  depends_on = [
    null_resource.demo_finance_advisor_build
  ]

  name                = "finance-advisor-service"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

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

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project  = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service  = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}