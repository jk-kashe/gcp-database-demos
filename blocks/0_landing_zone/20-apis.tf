resource "null_resource" "enable_service_usage_api" {
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com --project ${local.project_id}"
  }
}

#Enable APIs
locals {
  apis_to_enable = [
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

resource "google_project_service" "project_services" {
  for_each           = toset(local.apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api]
  project            = local.project_id
}