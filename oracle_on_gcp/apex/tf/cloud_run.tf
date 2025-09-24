resource "google_artifact_registry_repository" "ords_remote" {
  location      = var.region
  repository_id = "ords-remote"
  description   = "Remote repository for ORDS container images"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"

  remote_repository_config {
    docker_repository {
      custom_repository {
        uri = "https://container-registry.oracle.com"
      }
    }
  }

  depends_on = [google_project_service.api["artifactregistry.googleapis.com"]]
}

resource "google_cloud_run_v2_service" "ords" {
  name     = "ords"
  location = var.region

  template {
    containers {
      image = "${google_artifact_registry_repository.ords_remote.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_remote.repository_id}/database/ords-developer:24.4.0"

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
    google_artifact_registry_repository.ords_remote
  ]
}

output "apex_url" {
  value = google_cloud_run_v2_service.ords.uri
}
