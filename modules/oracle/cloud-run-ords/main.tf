# Enable APIs
resource "google_project_service" "api" {
  for_each = toset(var.apis)

  service            = each.value
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_api" {
  create_duration = "60s"

  depends_on = [google_project_service.api]
}

# Repository for the custom ORDS container image
resource "google_artifact_registry_repository" "ords_custom" {
  location      = var.region
  repository_id = "ords-custom"
  description   = "Repository for custom ORDS container images"
  format        = "DOCKER"

  depends_on = [google_project_service.api["artifactregistry.googleapis.com"]]
}

# Build the custom ORDS container image using Cloud Build
resource "null_resource" "ords_container_build" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/files/ords-container/Dockerfile")
    script_hash     = filemd5("${path.module}/files/ords-container/start.sh")
  }

  provisioner "local-exec" {
    command = "gcloud builds submit --tag ${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:latest ${path.module}/files/ords-container"
  }

  depends_on = [
    google_artifact_registry_repository.ords_custom,
    var.iam_dependency
  ]
}

data "google_project" "project" {}

resource "google_cloud_run_v2_service" "ords" {
  provider = google-beta
  name     = "ords"
  location = var.region
  deletion_protection = false
  ingress      = "INGRESS_TRAFFIC_ALL"
  launch_stage = "BETA"
  iap_enabled  = true

  template {
    containers {
      image = "${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:latest"

      env {
        name  = "CONN_STRING"
        value = "SYS/${var.vm_oracle_password}@${var.oracle_db_ip}:1521/FREEPDB1"
      }

      resources {
        limits = {
          memory = "2Gi"
          cpu    = "1"
        }
      }
    }

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    var.db_instance_dependency,
    null_resource.ords_container_build
  ]
}

resource "google_cloud_run_v2_service_iam_member" "iap_invoker" {
  project = google_cloud_run_v2_service.ords.project
  location = google_cloud_run_v2_service.ords.location
  name = google_cloud_run_v2_service.ords.name
  role   = "roles/run.invoker"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-iap.iam.gserviceaccount.com"
  depends_on = [google_cloud_run_v2_service.ords]
}
