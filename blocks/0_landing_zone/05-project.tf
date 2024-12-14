#Use EXISTING project
#----------------------------------------------------------
resource "null_resource" "enable_service_usage_api_pre_proj" {
  count = var.create_new_project ? 0 : 1
  provisioner "local-exec" {
    command = "gcloud services enable serviceusage.googleapis.com --project ${var.demo_project_id}"
  }
}

resource "google_project_service" "project_rm_api" {
  count              = var.create_new_project ? 0 : 1 
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api_pre_proj]
  project            = var.demo_project_id
}

data "google_project" "project_check" {
  count      = var.create_new_project ? 0 : 1
  project_id = var.demo_project_id
  depends_on = [google_project_service.project_rm_api]
}


#Use NEW project
#----------------------------------------------------------
#enable cloud billing api on the project running tf from
resource "null_resource" "enable_cloud_billing_api" {
  count = var.create_new_project ? 1 : 0

  provisioner "local-exec" {
    command = "gcloud services enable cloudbilling.googleapis.com"
  }
}

#Create Project
resource "random_id" "unique_project_suffix" {
  count = var.create_new_project ? 1 : 0
  byte_length = 3 
}

#project provider seems to set org_id, but since config doesn't
#that makes project get re-created on every run
#with this, we read org_id _from the project used to create environment_
#once so there are no issues on subsequential runs
data "external" "org_id" {
  count = var.create_new_project ? 1 : 0

  program = [
    "bash",
    "-c",
    <<EOT
      org_id=$(gcloud projects describe $(gcloud config get-value project) \
      --format='value(parent.id)')
      
      echo '{"org_id": "'"$org_id"'"}'
    EOT
  ]
}

resource "google_project" "demo-project" {
  count      = var.create_new_project ? 1 : 0
  name       = "${var.demo_project_id}-${random_id.unique_project_suffix[0].hex}"
  project_id = "${var.demo_project_id}-${random_id.unique_project_suffix[0].hex}"
  org_id     = data.external.org_id[0].result.org_id
  billing_account = var.billing_account_id
  depends_on = [null_resource.enable_cloud_billing_api ]
}

locals {
  project_id     = var.create_new_project ? google_project.demo-project[0].project_id : data.google_project.project_check[0].project_id
  project_name   = var.create_new_project ? google_project.demo-project[0].name : data.google_project.project_check[0].name
  project_number = var.create_new_project ? google_project.demo-project[0].number : data.google_project.project_check[0].number
}