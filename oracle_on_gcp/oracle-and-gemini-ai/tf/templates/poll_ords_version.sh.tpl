#!/bin/bash

COUNTER=0
# 40 retries * 60s = 2400s = 40 minutes
MAX_RETRIES=40
VM_NAME="${vm_name}"
ZONE="${zone}"
PROJECT_ID="${project_id}"
OUTPUT_FILE="${output_file}"

echo "Starting to poll for ORDS version via direct SSH..."

while true; do
  # Use gcloud ssh to execute the command directly inside the container.
  # The "2>/dev/null" is now inside the command string to suppress errors on the remote host.
  VERSION=$(gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo docker exec oracle-free rpm -q --qf '%%{VERSION}' ords 2>/dev/null" 2>/dev/null | tr -d '\r')
  
  # Check if we got a non-empty version string that doesn't contain an error message.
  if [[ -n "$VERSION" && "$VERSION" != *"not installed"* && "$VERSION" != *"No such container"* ]]; then
    echo "Success! Found ORDS version: $VERSION"
    # Write the value to the output file for Terraform to read
    echo -n "$VERSION" > "$OUTPUT_FILE"
    exit 0
  fi

  ((COUNTER++))
  if ((COUNTER > MAX_RETRIES)); then
    echo "Error: Timed out waiting for ORDS installation on VM $VM_NAME."
    # Optional: print the last received value for debugging
    echo "Last received value: $VERSION"
    exit 1
  fi

  echo "ORDS not yet installed or container not ready. Waiting... (Attempt $${COUNTER}/$${MAX_RETRIES})"
  sleep 60
done
