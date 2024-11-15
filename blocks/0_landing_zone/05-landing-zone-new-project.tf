#enable cloud billing api on the project running tf from
resource "null_resource" "enable_cloud_billing_api" {
  provisioner "local-exec" {
    command = "gcloud services enable cloudbilling.googleapis.com"
  }
}

#Create Project
resource "random_id" "unique_project_suffix" {
  byte_length = 3 
}

#project provider seems to set org_id, but since config doesn't
#that makes project get re-created on every run
#with this, we read org_id _from the project used to create environment_
#once so there are no issues on subsequential runs
data "external" "org_id" {
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
  name       = "${var.demo_project_id}-${random_id.unique_project_suffix.hex}"
  project_id = "${var.demo_project_id}-${random_id.unique_project_suffix.hex}"
  org_id     = data.external.org_id.result.org_id
  billing_account = var.billing_account_id
  depends_on = [null_resource.enable_cloud_billing_api ]
}

locals {
  project_id     = google_project.demo-project.project_id
  project_name   = google_project.demo-project.name
  project_number = google_project.demo-project.number
}

output "project_id" {
  value = google_project.demo-project.project_id
}