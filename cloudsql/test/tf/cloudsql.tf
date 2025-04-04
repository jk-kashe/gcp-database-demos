#Enable APIs
locals {
  cloudsql_apis_to_enable = [
    "sqladmin.googleapis.com",      # Cloud SQL Admin API
    "aiplatform.googleapis.com",    # Keep if Vertex AI is used by the *application*
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com" # Needed for private IP
  ]
}

resource "google_project_service" "cloudsql_services" {
  for_each           = toset(local.cloudsql_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  depends_on         = [null_resource.enable_service_usage_api] # from landing_zone.tf
  project            = local.project_id                          # from landing_zone.tf
}

# Note: Requires google_service_networking_connection from landing_zone.tf
resource "time_sleep" "wait_for_service_networking" {
  create_duration = "30s"
  depends_on = [
    google_service_networking_connection.private_service_access, # from landing_zone.tf
    google_project_service.cloudsql_services
  ]
}

# Cloud SQL Instance
resource "google_sql_database_instance" "primary" {
  name             = var.db_instance_name
  database_version = "POSTGRES_15" # Choose appropriate version
  region           = var.region
  project          = local.project_id

  settings {
    tier = var.db_tier
    ip_configuration {
      ipv4_enabled    = false        # Disable public IP
      private_network = google_compute_network.demo_network.id # from landing_zone.tf
    }
    disk_autoresize = true
    disk_size       = var.db_disk_size
    disk_type       = "PD_SSD"
    # Add backups, maintenance window, flags etc. as needed
    # database_flags {
    #   name  = "cloudsql.enable_pgvector"
    #   value = "on"
    # } # pgvector is enabled by default on PG15+
  }

  # Set the root password (for 'postgres' user by default)
  root_password = var.db_password

  deletion_protection = false # Set to true for production

  depends_on = [time_sleep.wait_for_service_networking]
}

# Cloud SQL Database within the instance
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.primary.name
  project  = local.project_id
}

#Add Cloud SQL Client role to the default compute SA
locals {
  default_compute_sa_roles = [
    "roles/cloudsql.client",   # Role needed to connect via Private IP / Auth Proxy
    "roles/aiplatform.user"    # Keep if client VM needs to interact with Vertex AI directly
  ]
}

resource "google_project_iam_member" "default_compute_sa_cloudsql_client" {
  for_each = toset(local.default_compute_sa_roles)
  project  = local.project_id
  role     = each.key
  member   = "serviceAccount:${local.project_number}-compute@developer.gserviceaccount.com" # from landing_zone.tf
  depends_on = [
    time_sleep.wait_for_database_clientvm_boot, # from landing_zone.tf
    google_sql_database_instance.primary
  ]
}

#Install and config Postgres Client on VM
resource "null_resource" "install_postgresql_client" {
  depends_on = [
    google_project_iam_member.default_compute_sa_cloudsql_client,
    google_sql_database.database # Ensure DB exists before trying to connect
  ]

  triggers = {
    # Re-run if the client VM or DB instance changes
    clientvm_name = var.clientvm-name
    db_ip         = google_sql_database_instance.primary.private_ip_address
    project_id    = local.project_id
    region        = var.region
    zone          = var.zone
  }


  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute ssh ${self.triggers.clientvm_name} --zone=${self.triggers.region}-${self.triggers.zone} --tunnel-through-iap \
      --project ${self.triggers.project_id} --command='touch ~/.profile && \
      echo "Updating apt..." && \
      sudo apt-get update -y && \
      echo "Installing postgresql-client and utils..." && \
      sudo apt-get install -y postgresql-client zip unzip && \
      echo "Updating .profile..." && \
      echo "export PROJECT_ID=${self.triggers.project_id}" >> ~/.profile && \
      echo "export REGION=${self.triggers.region}" >> ~/.profile && \
      echo "export DBINSTANCE=${var.db_instance_name}" >> ~/.profile && \
      echo "export PGHOST=${self.triggers.db_ip}" >> ~/.profile && \
      echo "export PGDATABASE=${var.db_name}" >> ~/.profile && \
      echo "export PGUSER=postgres" >> ~/.profile && \
      echo "Client VM setup complete."'
    EOT
  }
}

# Script to SSH into client VM
resource "local_file" "cloudsql_client_script" {
  filename = "../cloudsql-client.sh" # Renamed script
  content  = <<-EOT
#!/bin/bash
gcloud compute ssh ${var.clientvm-name} --zone=${var.region}-${var.zone} --tunnel-through-iap \
--project ${local.project_id}
  EOT
  file_permission = "0755" # Make it executable
}

# Create pgauth.env file locally
resource "local_sensitive_file" "cloudsql_pgauth" {
  filename = "files/pgauth.env" # Keep filename, content changes
  content = templatefile("templates/db-cloudsql-pgauth.env.tftpl", {
    pghost     = google_sql_database_instance.primary.private_ip_address
    pguser     = "postgres"
    pgpassword = var.db_password
    pgdatabase = var.db_name
    pgsslmode  = "disable" # Use "require" if SSL is configured and enforced
  })
}

# Copy pgauth.env to client VM
resource "null_resource" "copy_pgauth_to_vm" {
  depends_on = [
    null_resource.install_postgresql_client,
    local_sensitive_file.cloudsql_pgauth
  ]

  triggers = {
    # Re-run if the source file or destination details change
    pgauth_content = local_sensitive_file.cloudsql_pgauth.content
    clientvm_name  = var.clientvm-name
    project_id     = local.project_id
    region         = var.region
    zone           = var.zone
  }

  provisioner "local-exec" {
    command = <<-EOT
  gcloud compute scp ${local_sensitive_file.cloudsql_pgauth.filename} ${self.triggers.clientvm_name}:~/ \
    --zone=${self.triggers.region}-${self.triggers.zone} \
    --tunnel-through-iap \
    --project ${self.triggers.project_id}
  EOT
  }
}

# Grant necessary roles to the Cloud SQL Service Agent *IF* needed
# e.g., if Cloud SQL needs to access KMS or other services.
# For basic operation and Vertex AI access *from the application*, this is likely not needed.
# Remove the AlloyDB SA role grant.

# Run initial DB setup script (vector extension)
resource "null_resource" "db_cloudsql_setup" {
  depends_on = [
    null_resource.copy_pgauth_to_vm # Ensure pgauth.env is present
  ]

  triggers = {
    # Re-run if connection details or script changes
    db_ip         = google_sql_database_instance.primary.private_ip_address
    db_password   = var.db_password # Use sensitive variable directly in trigger
    clientvm_name = var.clientvm-name
    project_id    = local.project_id
    region        = var.region
    zone          = var.zone
    sql_script    = file("files/db-cloudsql-setup.sql") # Trigger if script content changes
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Copying Cloud SQL setup script..."
      gcloud compute scp files/db-cloudsql-setup.sql ${self.triggers.clientvm_name}:~/ \
      --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id}

      echo "Running Cloud SQL setup script..."
      gcloud compute ssh ${self.triggers.clientvm_name} --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id} \
      --command='source pgauth.env && psql -f ~/db-cloudsql-setup.sql'
    EOT

    environment = {
      # Pass password via environment variable for security
      PGPASSWORD = self.triggers.db_password
    }
  }
}