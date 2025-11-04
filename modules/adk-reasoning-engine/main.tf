resource "google_storage_bucket" "staging" {
  name                          = var.staging_bucket_name
  location                      = var.region
  force_destroy                 = true
  uniform_bucket_level_access = true
}

resource "local_file" "agent_py" {
  content = templatefile("${path.module}/templates/agent.py.tpl", {
    mcp_toolbox_url              = var.mcp_toolbox_url
    adk_agent_model              = var.adk_agent_model
    adk_agent_name               = var.adk_agent_name
    adk_agent_description        = var.adk_agent_description
    adk_agent_instruction        = var.adk_agent_instruction
    adk_agent_include_thoughts   = var.adk_agent_include_thoughts ? "True" : "False"
    adk_agent_thinking_budget    = var.adk_agent_thinking_budget
  })
  filename = "${path.module}/src/agent.py"
}

resource "local_file" "deploy_py" {
  content = templatefile("${path.module}/templates/deploy.py.tpl", {})
  filename = "${path.module}/deploy.py"
}

resource "local_file" "cli_deploy_script" {
  content = templatefile("${path.module}/templates/cli_deploy.sh.tpl", {
    project_id          = var.project_id,
    region              = var.region,
    staging_bucket_name = google_storage_bucket.staging.name,
    agent_display_name  = var.agent_display_name,
    agent_app_name      = var.agent_app_name,
    agent_src_path      = "${path.module}/src",
    output_file_path    = "${path.module}/reasoning_engine.txt"
  })
  filename = "${path.module}/cli_deploy.sh"

  provisioner "local-exec" {
    command = "chmod +x ${self.filename}"
  }
}

resource "null_resource" "deploy_agent" {
  depends_on = [local_file.agent_py, local_file.deploy_py, local_file.cli_deploy_script]

  provisioner "local-exec" {
    command = "bash ${local_file.cli_deploy_script.filename}"
  }
}

data "local_file" "reasoning_engine" {
  depends_on = [null_resource.deploy_agent]
  filename   = "${path.module}/reasoning_engine.txt"
}

resource "local_file" "undeploy_py" {
  content = templatefile("${path.module}/templates/undeploy.py.tpl", {})
  filename = "${path.module}/src/undeploy.py"
}

resource "local_file" "run_python_undeploy_script" {
  content = templatefile("${path.module}/templates/run_python_undeploy.sh.tpl", {
    reasoning_engine_resource_name = trimspace(data.local_file.reasoning_engine.content)
  })
  filename = "${path.module}/run_python_undeploy.sh"

  provisioner "local-exec" {
    command = "chmod +x ${self.filename}"
  }
}

resource "null_resource" "undeploy_agent" {
  depends_on = [
    local_file.undeploy_py,
    local_file.run_python_undeploy_script
  ]

  triggers = {
    script_hash = local_file.run_python_undeploy_script.content_sha1
    script_filename = local_file.run_python_undeploy_script.filename
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${self.triggers.script_filename}"
  }
}

resource "local_file" "invoke_py" {
  depends_on = [null_resource.deploy_agent]
  content = templatefile("${path.module}/templates/invoke.py.tpl", {
    project_id          = var.project_id,
    location            = var.region,
    reasoning_engine_id = trimspace(data.local_file.reasoning_engine.content)
  })
  filename = "${path.module}/src/invoke.py"
}