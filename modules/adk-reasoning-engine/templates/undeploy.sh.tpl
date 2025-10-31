#!/bin/bash
set -e

RESOURCE_NAME="${reasoning_engine_resource_name}"

# Exit if the resource name is empty or the file doesn't exist
if [ -z "$RESOURCE_NAME" ]; then
  echo "Reasoning engine resource name is empty. Skipping deletion."
  exit 0
fi

# Extract location from the resource name (e.g., projects/proj/locations/loc/...)
LOCATION=$(echo "$RESOURCE_NAME" | cut -d'/' -f4)

if [ -z "$LOCATION" ]; then
  echo "Could not parse location from resource name: $RESOURCE_NAME"
  # We will not exit with 1, because this would prevent destroying other resources
  exit 0
fi

API_ENDPOINT="https://${LOCATION}-aiplatform.googleapis.com/v1/${RESOURCE_NAME}"

echo ">>> Deleting ADK Reasoning Engine via REST API: $RESOURCE_NAME"
curl -f -s -X DELETE \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     "$API_ENDPOINT" > /dev/null || echo "Deletion of $RESOURCE_NAME failed or it was already deleted."

echo
echo ">>> Deletion command issued for $RESOURCE_NAME"
