# Depends on:
# landing_zone.tf (for project, network, clientvm base)
# cloudsql.tf (for db instance)

# Execute Cymbal Air DB creation/setup script (vector extension)
resource "null_resource" "cymbal_air_demo_exec_db_script" {
  depends_on = [
    null_resource.db_cloudsql_setup # Depends on the general DB setup now
  ]

  triggers = {
    # Re-run if connection details or script changes
    db_ip         = google_sql_database_instance.primary.private_ip_address
    db_password   = var.db_password
    clientvm_name = var.clientvm-name
    project_id    = local.project_id
    region        = var.region
    zone          = var.zone
    sql_script    = file("files/demo-cymbal-air-create-db.sql")
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Copying Cymbal Air DB create script..."
      gcloud compute scp files/demo-cymbal-air-create-db.sql ${self.triggers.clientvm_name}:~/ \
      --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id}

      echo "Running Cymbal Air DB create script..."
      gcloud compute ssh ${self.triggers.clientvm_name} --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id} \
      --command='source pgauth.env && psql -f ~/demo-cymbal-air-create-db.sql'
    EOT
    environment = {
      PGPASSWORD = self.triggers.db_password
    }
  }
}

# Create Cymbal Air config.yml locally
resource "local_file" "cymbal_air_config" {
  filename = "files/config.yml"
  content = templatefile("templates/demo-cymbal-air-config.yml.tftpl", {
    project   = local.project_id
    region    = var.region
    # Cloud SQL Specifics: Use instance connection name for Auth Proxy or IP for direct
    # Using Instance Connection Name is generally recommended for Cloud Run
    instance_connection_name = google_sql_database_instance.primary.connection_name
    # Alternatively, for direct private IP:
    # db_host = google_sql_database_instance.primary.private_ip_address
    database = var.db_name
    username = "postgres"
    password = var.db_password # Pass the sensitive variable to the template
  })
  depends_on = [google_sql_database_instance.primary]
}



#Fetch and Configure the demo
resource "null_resource" "cymbal_air_demo_fetch_and_config" {
  depends_on = [
    null_resource.cymbal_air_demo_exec_db_script,
    google_project_iam_member.default_compute_sa_roles_expanded, # from landing_zone.tf
    local_file.cymbal_air_config # Ensure config.yml is created first
  ]

  triggers = {
    # Re-run if relevant details change
    clientvm_name = var.clientvm-name
    project_id    = local.project_id
    region        = var.region
    zone          = var.zone
    config_yml    = local_file.cymbal_air_config.content
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Copying config.yml to client VM..."
      gcloud compute scp files/config.yml ${self.triggers.clientvm_name}:~/ \
      --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id}

      echo "Running demo fetch and config steps on client VM..."
      gcloud compute ssh ${self.triggers.clientvm_name} --zone=${self.triggers.region}-${self.triggers.zone} \
      --tunnel-through-iap \
      --project ${self.triggers.project_id} \
      --command='
        echo "Updating apt and installing Python/Git..."
        sudo apt-get update -y && sudo apt-get install -y python3.11-venv git

        echo "Setting up Python virtual environment..."
        python3 -m venv .venv
        source .venv/bin/activate
        pip install --upgrade pip

        echo "Cloning application repository..."
        # Consider parameterizing the repo/branch if needed
        rm -rf genai-databases-retrieval-app # Remove old clone if exists
        git clone --depth 1 --branch v0.1.0/fix/alloydb https://github.com/jk-kashe/genai-databases-retrieval-app/
        # IMPORTANT: The above branch still mentions alloydb. The *code* within this repo
        # in datastore/providers/ MUST be updated to support Cloud SQL (e.g., using
        # cloud-sql-python-connector or pg8000 with direct IP/Auth Proxy).
        # The sed command below is removed as it targeted alloydb.py.

        echo "Moving config.yml into place..."
        mv ~/config.yml ~/genai-databases-retrieval-app/retrieval_service/

        cd genai-databases-retrieval-app/retrieval_service

        echo "Installing Python requirements..."
        pip install -r requirements.txt

        echo "Running database initialization script (app level)..."
        # This script needs to correctly use the config.yml to connect to Cloud SQL
        python run_database_init.py

        echo "Demo fetch and config complete."
      '
    EOT
  }
}