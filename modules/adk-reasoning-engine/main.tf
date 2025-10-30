resource "google_storage_bucket" "staging" {
  name                          = var.staging_bucket_name
  location                      = var.region
  force_destroy                 = true
  uniform_bucket_level_access = true
}

resource "local_file" "agent_py" {
  content = templatefile("${path.module}/src/main.py.tpl", {
    mcp_toolbox_url              = var.mcp_toolbox_url
    adk_agent_model              = var.adk_agent_model
    adk_agent_name               = var.adk_agent_name
    adk_agent_description        = var.adk_agent_description
    adk_agent_instruction        = var.adk_agent_instruction
    adk_agent_include_thoughts   = var.adk_agent_include_thoughts ? "True" : "False"
    adk_agent_thinking_budget    = var.adk_agent_thinking_budget
  })
  filename = "${path.module}/src/main.py"
}

resource "local_file" "deploy_script" {
  content = templatefile("${path.module}/deploy.sh.tpl", {
    project_id          = var.project_id,
    region              = var.region,
    staging_bucket_name = google_storage_bucket.staging.name,
    agent_display_name  = var.agent_display_name,
    agent_app_name      = var.agent_app_name,
    agent_src_path      = "${path.module}/src",
    output_file_path    = "${path.module}/reasoning_engine.txt"
  })
  filename = "${path.module}/deploy.sh"
}

resource "null_resource" "deploy_agent" {
  depends_on = [local_file.agent_py, local_file.deploy_script]

  provisioner "local-exec" {
    command = "bash ${local_file.deploy_script.filename}"
  }
}

data "local_file" "reasoning_engine" {
  depends_on = [null_resource.deploy_agent]
  filename   = "${path.module}/reasoning_engine.txt"
}