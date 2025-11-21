output "client_vm_name" {
  value = var.clientvm_name
}

output "client_vm_zone" {
  value = "${var.region}-${var.zone}"
}

output "install_dependency" {
  value = null_resource.install_oracle_client.id
}
