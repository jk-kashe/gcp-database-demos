#!/bin/bash
set -e

COUNTER=0
# 40 retries * 60s = 2400s = 40 minutes
MAX_RETRIES=40
VM_NAME="${vm_name}"
ZONE="${zone}"
PROJECT_ID="${project_id}"
OUTPUT_FILE="${output_file}"

while true; do
  # Use --format="value(query_value)" to get only the version string
  VALUE=$(gcloud compute instances get-guest-attributes "$VM_NAME" --query-path="ords/version" --zone="$ZONE" --project="$PROJECT_ID" --format="value(query_value)")
  
  if [[ -n "$VALUE" ]]; then
    echo "Found ORDS version: $VALUE"
    # Write the value to the output file for Terraform to read
    echo -n "$VALUE" > "$OUTPUT_FILE"
    exit 0
  fi

  ((COUNTER++))
  if ((COUNTER > MAX_RETRIES)); then
    echo "Error: Timed out waiting for ORDS version attribute on VM $VM_NAME."
    exit 1
  fi

  echo "Waiting for ORDS version attribute... (Attempt $${COUNTER}/$${MAX_RETRIES})"
  sleep 60
done