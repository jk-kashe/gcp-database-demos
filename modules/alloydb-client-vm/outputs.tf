output "vm_instance" {
  value = module.bare-client-vm.vm_instance
}

output "provisioned" {
  value = null_resource.create_remote_pgauth
}
