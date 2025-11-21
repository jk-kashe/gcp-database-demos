module "bare-client-vm" {
  source = "../bare-client-vm"

  project_id                  = var.project_id
  project_number              = var.project_number
  region                      = var.region
  zone                        = var.zone
  network_id                  = var.network_id
  clientvm-name               = var.clientvm_name
  project_services_dependency = var.project_services_dependency
}

# Ensure SSH keys are configured
resource "null_resource" "init_gcloud_ssh" {
  provisioner "local-exec" {
    command = "gcloud compute config-ssh"
  }
  depends_on = [module.bare-client-vm]
}

resource "time_sleep" "wait_for_vm_boot" {
  create_duration = "90s"
  depends_on      = [null_resource.init_gcloud_ssh]
}

# Create the installation script locally
resource "local_file" "install_script" {
  filename = "${path.module}/files/install_oracle_client.sh"
  content  = <<-EOT
#!/bin/bash
set -e

# Create Oracle user and install dependencies
sudo useradd -m -s /bin/bash oracle || true
sudo apt-get update
sudo apt-get -o DPkg::Lock::Timeout=600 -y install unzip libaio1t64 wget
sudo ln -sf /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1

# Switch to oracle user to install Instant Client
sudo -u oracle bash -c '
  cd /home/oracle
  mkdir -p instantclient
  cd instantclient
  
  # Download Instant Client (using public URLs for 23ai Free)
  wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basic-linux.x64-23.4.0.24.05.zip
  wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-sqlplus-linux.x64-23.4.0.24.05.zip
  wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-tools-linux.x64-23.4.0.24.05.zip
  wget -q https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-sdk-linux.x64-23.4.0.24.05.zip
  
  unzip -o instantclient-basic-linux.x64-23.4.0.24.05.zip
  unzip -o instantclient-sqlplus-linux.x64-23.4.0.24.05.zip
  unzip -o instantclient-tools-linux.x64-23.4.0.24.05.zip
  unzip -o instantclient-sdk-linux.x64-23.4.0.24.05.zip
  
  # Configure environment variables in .bashrc
  echo "export LD_LIBRARY_PATH=/home/oracle/instantclient/instantclient_23_4" >> ~/.bashrc
  echo "export PATH=\$PATH:/home/oracle/instantclient/instantclient_23_4" >> ~/.bashrc
  echo "export TNS_ADMIN=/home/oracle/instantclient/instantclient_23_4/network/admin" >> ~/.bashrc
  
  # Create TNS Admin directory
  mkdir -p /home/oracle/instantclient/instantclient_23_4/network/admin
'
EOT
}

# Upload and execute the script
resource "null_resource" "install_oracle_client" {
  depends_on = [time_sleep.wait_for_vm_boot, local_file.install_script]

  provisioner "local-exec" {
    command = <<-EOT
      gcloud compute scp ${local_file.install_script.filename} ${var.clientvm_name}:/tmp/install_oracle_client.sh --zone=${var.region}-${var.zone} --tunnel-through-iap --project ${var.project_id}
      gcloud compute ssh ${var.clientvm_name} --zone=${var.region}-${var.zone} --tunnel-through-iap --project ${var.project_id} --command='chmod +x /tmp/install_oracle_client.sh && /tmp/install_oracle_client.sh'
    EOT
  }
}