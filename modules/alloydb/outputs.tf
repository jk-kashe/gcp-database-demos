output "primary_instance" {
    description = "The primary alloydb instance"
    value = google_alloydb_instance.primary_instance
}

output "alloydb_cluster" {
    description = "The alloydb cluster"
    value = google_alloydb_cluster.alloydb_cluster
}

output "cluster_name" {
    description = "The name of the alloydb cluster"
    value = google_alloydb_cluster.alloydb_cluster.name
}

output "primary_instance_name" {
    description = "The name of the primary alloydb instance"
    value = google_alloydb_instance.primary_instance.name
}

output "primary_instance_ip" {
    description = "The IP address of the primary alloydb instance"
    value = google_alloydb_instance.primary_instance.ip_address
}