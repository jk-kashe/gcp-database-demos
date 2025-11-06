#!/bin/bash

COUNTER=0
# 20 retries * 30s = 600s = 10 minutes
MAX_RETRIES=40
VM_NAME="${vm_name}"
ZONE="${zone}"
PROJECT_ID="${project_id}"
ORACLE_PASSWORD="${oracle_password}"

echo "Starting to poll for APEX readiness..."

while true; do
  # Use gcloud ssh to execute the command directly inside the container.
  # We are checking if we can connect and query an APEX view.
  APEX_READY=$(gcloud compute ssh "$VM_NAME" --zone="$ZONE" --project="$PROJECT_ID" --command="sudo docker exec oracle-free sqlplus -s sys/'$ORACLE_PASSWORD'@//localhost:1521/FREEPDB1 as sysdba <<< 'set heading off; set feedback off; select 1 from apex_release; exit;' 2>/dev/null | grep '1'")

  if [[ "$APEX_READY" == "1" ]]; then
    echo "Success! APEX is ready."
    exit 0
  fi

  ((COUNTER++))
  if ((COUNTER > MAX_RETRIES)); then
    echo "Error: Timed out waiting for APEX to become ready on VM $VM_NAME."
    exit 1
  fi

  echo "APEX not yet ready. Waiting... (Attempt $${COUNTER}/$${MAX_RETRIES})"
  sleep 60
done
