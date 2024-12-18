#Fetch and Configure the demo 
resource "null_resource" "demo_finance_advisor_fetch_and_config" {
  depends_on = [google_project_iam_member.default_compute_sa_roles_expanded]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source spanner.env
      sudo apt-get update
      sudo apt install -y python3.11-venv git
      python3 -m venv .demo_spanner_fin_venv
      source .demo_spanner_fin_venv/bin/activate
      pip install --upgrade pip
      git clone --depth 1 --branch fix/demo https://github.com/jk-kashe/generative-ai'
      
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source spanner.env
      source .demo_spanner_fin_venv/bin/activate
      cp spanner.env generative-ai/gemini/sample-apps/finance-advisor-spanner/.env
      cd generative-ai/gemini/sample-apps/finance-advisor-spanner/
      pip install -r requirements.txt'
    EOT
  }
}

#Build the retrieval service using Cloud Build
resource "null_resource" "demo_finance_advisor_build" {
  depends_on = [time_sleep.wait_for_sa_roles_expanded,
                null_resource.demo_finance_advisor_fetch_and_config]

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
      --project ${local.project_id} \
      --command='cd ~/generative-ai/gemini/sample-apps/finance-advisor-spanner/
      gcloud builds submit --tag ${var.region}-docker.pkg.dev/${local.project_id
}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest .'
    EOT
  }
}

#Deploy retrieval service to cloud run
resource "google_cloud_run_v2_service" "demo_finance_advisor_deploy" {
  name                = "finance-advisor-service"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  project             = local.project_id
  depends_on          = [ null_resource.demo_finance_advisor_build ]
  deletion_protection = false
  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${local.project_id
}/${google_artifact_registry_repository.demo_service_repo.repository_id}/finance-advisor-service:latest"
    }
    service_account = google_service_account.cloudrun_identity.email
    
    vpc_access{
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_v2_service.demo_finance_advisor_deploy.location
  project     = google_cloud_run_v2_service.demo_finance_advisor_deploy.project
  service     = google_cloud_run_v2_service.demo_finance_advisor_deploy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}