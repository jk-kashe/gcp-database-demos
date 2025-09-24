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
    dockerfile_hash = filemd5("ords-container/Dockerfile")
    script_hash     = filemd5("ords-container/start.sh")
  }

  provisioner "local-exec" {
    command = "gcloud builds submit --tag ${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:latest ords-container"
  }

  depends_on = [google_artifact_registry_repository.ords_custom]
}

resource "google_cloud_run_v2_service" "ords" {
  name     = "ords"
  location = var.region

  template {
    containers {
      image = "${google_artifact_registry_repository.ords_custom.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_custom.repository_id}/ords-custom:latest"

      env {
        name  = "CONN_STRING"
        value = "SYS/${var.vm_oracle_password}@${google_compute_instance.oracle_vm.network_interface[0].network_ip}:1521/FREEPDB1"
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.serverless.id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    null_resource.provision_db_vm,
    null_resource.ords_container_build
  ]
}

output "apex_url" {
  value = google_cloud_run_v2_service.ords.uri
}
