# Enable APIs
resource "google_project_service" "api" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# Repository for the proxy container image
resource "google_artifact_registry_repository" "ords_proxy" {
  location      = var.region
  repository_id = "ords-proxy"
  description   = "Repository for ORDS proxy container images"
  format        = "DOCKER"
  project       = var.project_id
  depends_on    = [google_project_service.api["artifactregistry.googleapis.com"]]
}

# Build the proxy container image using Cloud Build
resource "null_resource" "proxy_container_build" {
  triggers = {
    # Re-run the build if the Dockerfile or config changes
    dir_sha = sha1(join("", [for f in fileset("${path.module}/files/nginx", "*") : filesha1("${path.module}/files/nginx/${f}")]))
  }

  provisioner "local-exec" {
    command = "gcloud builds submit --tag ${google_artifact_registry_repository.ords_proxy.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_proxy.repository_id}/ords-proxy:latest ${path.module}/files/nginx --project ${var.project_id}"
  }

  depends_on = [
    google_artifact_registry_repository.ords_proxy,
    google_project_service.api["cloudbuild.googleapis.com"],
    var.iam_dependency
  ]
}

# Service Account for the Proxy
resource "google_service_account" "ords_proxy" {
  account_id   = "ords-proxy-sa"
  display_name = "ORDS Proxy Service Account"
  project      = var.project_id
}

locals {
  # Extract hostname from the full ORDS URI
  adb_hostname = regex("https://([^/]+)", var.ords_uri)[0]
}

module "cr_base" {
  source = "../../cr-base"

  project_id            = var.project_id
  region                = var.region
  service_name          = var.service_name
  container_image       = "${google_artifact_registry_repository.ords_proxy.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ords_proxy.repository_id}/ords-proxy:latest"
  service_account_email = google_service_account.ords_proxy.email
  vpc_connector_id      = var.vpc_connector_id
  invoker_users         = var.invoker_users
  use_iap               = var.use_iap
  container_port        = 8080

  env_vars = [
    {
      name  = "ADB_HOSTNAME"
      value = local.adb_hostname
    }
  ]

  depends_on = [
    null_resource.proxy_container_build
  ]
}
