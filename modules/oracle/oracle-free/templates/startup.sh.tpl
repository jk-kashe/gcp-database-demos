#!/bin/bash
exec > >(logger -t startup-script) 2>&1

sudo apt-get update
# Install gcsfuse using the modern, signed-by method
sudo apt-get install -y curl lsb-release
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
sudo apt-get update
sudo apt-get install -y docker.io gcsfuse

# Mount the GCS bucket with verbose logging
sudo mkdir -p /mnt/ords_config
sudo gcsfuse ${gcs_bucket_name} /mnt/ords_config --debug_gcs --debug_fuse
sudo chmod -R 777 /mnt/ords_config

curl -o /tmp/unattended_apex_install_23c.sh https://raw.githubusercontent.com/Pretius/pretius-23cfree-unattended-apex-installer/main/src/unattended_apex_install_23c.sh

# Remove conflicting directory creation from the install script
sudo sed -i '/mkdir \/etc\/ords/d' /tmp/unattended_apex_install_23c.sh

# Create the new entrypoint script with the wait logic
cat > /tmp/00_start_apex_ords_installer.sh <<'EOF'
#!/bin/bash
# Loop until the PDB is open and ready
until sqlplus -s / as sysdba <<< "SELECT open_mode FROM v\$pdbs WHERE name = 'FREEPDB1';" | grep -q "READ WRITE"; do
  echo "Waiting for PDB FREEPDB1 to open..."
  sleep 10
done
echo "PDB FREEPDB1 is open. Starting APEX installation."
# Now, execute the main installation script
sh /home/oracle/unattended_apex_install_23c.sh
# After installation, configure ORDS to allow CORS from any origin
sed -i '/<\/properties>/i <entry key="security.externalSessionTrustedOrigins">*</entry>' /etc/ords/config/global/settings.xml
EOF

# Modify the main installation script to set passwords
sudo sed -i "s/OrclAPEX1999!/${apex_admin_password}/g" /tmp/unattended_apex_install_23c.sh
sudo sed -i "s/ALTER USER APEX_PUBLIC_USER IDENTIFIED BY E;/ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ${db_user_password};/g" /tmp/unattended_apex_install_23c.sh
# In the ORDS install heredoc, replace the first password placeholder with the SYS password
sudo sed -i "0,/^E$/s//${vm_oracle_password}/" /tmp/unattended_apex_install_23c.sh
# Then, replace the second (now only) password placeholder with the APEX_PUBLIC_USER password
sudo sed -i "s/^E$/${db_user_password}/" /tmp/unattended_apex_install_23c.sh

# Inject the version reporting command into the installation script
sudo sed -i "/dnf install ords -y/a ORDS_VERSION=\$(rpm -q --qf '%%{VERSION}' ords) \&\& curl -X PUT --data \"\$${ORDS_VERSION}\" -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes/ords/version" /tmp/unattended_apex_install_23c.sh

# Create and start the container
if [ ! "$(sudo docker ps -a -q -f name=oracle-free)" ]; then
  echo "Container 'oracle-free' not found. Running initial setup..."
  sudo docker rm -f oracle-free || true
  sudo docker create --name oracle-free -p 1521:1521 -p 8080:8080 -v /mnt/ords_config:/etc/ords/config --log-driver=gcplogs --restart=always -e ORACLE_PWD=${vm_oracle_password} container-registry.oracle.com/database/free:latest
  sudo docker cp /tmp/unattended_apex_install_23c.sh oracle-free:/home/oracle/unattended_apex_install_23c.sh
  sudo docker cp /tmp/00_start_apex_ords_installer.sh oracle-free:/opt/oracle/scripts/startup/00_start_apex_ords_installer.sh
  sudo docker start oracle-free
else
  echo "Container 'oracle-free' already exists. Skipping creation."
fi
