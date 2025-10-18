#!/bin/bash
set -e

COUNTER=0
# 40 retries * 60s = 2400s = 40 minutes
MAX_RETRIES=40
VM_NAME="${vm_name}"
ZONE="${zone}"
PROJECT_ID="${project_id}"

while true; do
  VALUE=$(gcloud compute instances get-guest-attributes "$VM_NAME" --query-path="ords/version" --zone="$ZONE" --project="$PROJECT_ID" 2>/dev/null)
  if [[ -n "$VALUE" ]]; then
    echo "Found ORDS version: $VALUE"
    # Output the value so Terraform can capture it if needed, though we're just using this for polling.
    echo "$VALUE"
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
