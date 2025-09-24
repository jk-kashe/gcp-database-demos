resource "google_cloud_run_v2_service" "ords" {
  name     = "ords"
  location = var.region
  
  template {
    containers {
      image = "container-registry.oracle.com/database/ords-developer:24.4.0"
      
      env {
        name  = "CONN_STRING"
        value = "SYS/${var.vm_oracle_password}@${google_compute_instance.oracle_vm.network_interface[0].network_ip}:1521/FREEPDB1"
      }
    }
    
    vpc_access {
      connector = google_vpc_access_connector.serverless.id
      egress    = "ALL_TRAFFIC"
    }
  }
  
  depends_on = [null_resource.provision_db_vm]
}

output "apex_url" {
  value = google_cloud_run_v2_service.ords.uri
}
