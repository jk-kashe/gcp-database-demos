output "primary_instance" {
    description = "The primary alloydb instance"
    value = google_alloydb_instance.primary_instance
}

output "alloydb_cluster" {
    description = "The alloydb cluster"
    value = google_alloydb_cluster.alloydb_cluster
}

output "install_postgresql_client" {
    description = "The null_resource for installing postgresql client."
    value = null_resource.install_postgresql_client
}

output "create_remote_pgauth" {
  description = "The null_resource for creating the remote pgauth file."
  value       = null_resource.create_remote_pgauth
}