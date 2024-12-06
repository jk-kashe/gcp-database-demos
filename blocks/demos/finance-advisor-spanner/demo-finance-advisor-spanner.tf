#TODO - this is very similar to cymbal-air, should be common

#Add required roles to the default compute SA (used by clientVM and Cloud Build)
locals {
  default_compute_sa_roles_expanded = [
    "roles/cloudbuild.builds.editor",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "default_compute_sa_roles_expanded" {
  for_each = toset(local.default_compute_sa_roles_expanded)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_database_clientvm_boot]
}



#Create and run Create db script
# resource "null_resource" "cymbal_air_demo_create_db_script" {
#   depends_on = [null_resource.install_postgresql_client]

#   provisioner "local-exec" {
#     command = <<-EOT
#       gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-a --tunnel-through-iap \
#       --project ${local.project_id} \
#       --command='cat <<EOF > ~/demo-cymbal-air-create-db.sql
#       CREATE DATABASE assistantdemo;
#       \c assistantdemo
#       CREATE EXTENSION vector;
#       EOF'
#     EOT
#   }
# }

# resource "null_resource" "cymbal_air_demo_exec_db_script" {
#   depends_on = [null_resource.alloydb_pgauth,
#                 null_resource.install_postgresql_client]

#   triggers = {
#     instance_ip     = "${google_alloydb_instance.primary_instance.ip_address}"
#     password        = var.alloydb_password
#     region          = var.region
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       gcloud compute scp demo-cymbal-air-create-db.sql ${var.clientvm-name}:~/ \
#       --zone=${var.region}-${var.zone} \
#       --tunnel-through-iap \
#       --project ${local.project_id}

#       gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
#       --tunnel-through-iap \
#       --project ${local.project_id} \
#       --command='source pgauth.env
#       psql -f ~/demo-cymbal-air-create-db.sql'
#     EOT
#   }

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = <<EOT
  #     gcloud compute ssh ${var.clientvm-name} --zone=${self.triggers.region}-a \
  #     --tunnel-through-iap --command='export PGHOST=${self.triggers.instance_ip}
  #     export PGUSER=postgres
  #     export PGPASSWORD=${self.triggers.password}
  #     psql -c 'DROP DATABASE assistantdemo'
  #   EOT
  # }
# }


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
      git clone --depth 1 https://github.com/GoogleCloudPlatform/generative-ai'
      
      gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} \
      --tunnel-through-iap \
      --project ${local.project_id} \
      --command='source spanner.env
      source .demo_spanner_fin_venv/bin/activate
      cp spanner.env generative-ai/gemini/sample-apps/finance-advisor-spanner/.env
      cd generative-ai/gemini/sample-apps/finance-advisor-spanner/
      pip install -r requirements.txt
     
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
}/${google_artifact_registry_repository.retrieval_service_repo.repository_id}/finance-advisor-service:latest .'
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
}/${google_artifact_registry_repository.retrieval_service_repo.repository_id}/finance-advisor-service:latest"
    }
    service_account = google_service_account.retrieval_identity.email
    
    vpc_access{
      network_interfaces {
        network = google_compute_network.demo_network.id
      }
    }

  }
}