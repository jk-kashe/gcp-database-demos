resource "local_file" "update_settings_sh" {
  content = templatefile("${path.module}/templates/update_settings.sh.tpl", {
    mcp_server_url = google_cloud_run_v2_service.mcp_server.uri
  })
  filename = "${path.module}/../update_settings.sh"
}

resource "null_resource" "run_update_settings" {
  depends_on = [local_file.update_settings_sh]

  provisioner "local-exec" {
    command = "cd ${path.module}/../ && chmod +x update_settings.sh && ./update_settings.sh"
  }
}
