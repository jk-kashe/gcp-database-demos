resource "google_service_account" "adk_agent" {
  project      = var.project_id
  account_id   = var.service_name
  display_name = "ADK Agent Service Account"
}

resource "google_artifact_registry_repository" "adk_agent" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.service_name}-repo"
  format        = "DOCKER"
  description   = "Docker repository for ADK agent images"
}

# This resource will trigger a cloud build to create the container image
# It runs synchronously, so the image will exist before the next resource is created.
resource "null_resource" "build_adk_agent_image" {
  # Triggers a new build if the source code changes
  triggers = {
    main_py_hash      = filesha256("${path.module}/adk-agent/main.py")
    dockerfile_hash   = filesha256("${path.module}/adk-agent/Dockerfile")
    requirements_hash = filesha256("${path.module}/adk-agent/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<-EOT
      gcloud builds submit ${path.module}/adk-agent \
        --project=${var.project_id} \
        --config=${path.module}/adk-agent/cloudbuild.yaml \
        --substitutions=_SERVICE_NAME=${var.service_name},_REGION=${var.region},_REPO_NAME=${google_artifact_registry_repository.adk_agent.repository_id}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [
    google_artifact_registry_repository.adk_agent
  ]
}

locals {
  invokers = length(var.invoker_users) > 0 ? var.invoker_users : []
}

module "cr_base" {
  source = "../cr-base"

  project_id            = var.project_id
  region                = var.region
  service_name          = var.service_name
  container_image       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.adk_agent.repository_id}/${var.service_name}:latest"
  service_account_email = google_service_account.adk_agent.email
  use_iap               = false
  invoker_users         = local.invokers
  env_vars = [
    {
      name  = "MCP_TOOLBOX_URL"
      value = var.mcp_toolbox_url
    },
    {
      name  = "ADK_AGENT_MODEL"
      value = var.adk_agent_model
    },
    {
      name  = "ADK_AGENT_NAME"
      value = var.adk_agent_name
    },
    {
      name  = "ADK_AGENT_DESCRIPTION"
      value = var.adk_agent_description
    },
    {
      name  = "ADK_AGENT_INSTRUCTION"
      value = var.adk_agent_instruction
    },
    {
      name  = "ADK_AGENT_INCLUDE_THOUGHTS"
      value = var.adk_agent_include_thoughts
    },
    {
      name  = "ADK_AGENT_THINKING_BUDGET"
      value = var.adk_agent_thinking_budget
    }
  ]

  depends_on = [
    null_resource.build_adk_agent_image
  ]
}