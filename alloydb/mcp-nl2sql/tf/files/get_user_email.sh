#!/bin/bash
set -e

# Try to get the email using a reliable gcloud command
EMAIL=$(gcloud config get-value account 2>/dev/null)

# If the email is still empty, exit with an error
if [ -z "$EMAIL" ]; then
  # This error will be visible to Terraform and the user
  echo "Error: Could not determine gcloud email. Please make sure you are authenticated with 'gcloud auth login'." >&2
  exit 1
fi

# If we have an email, print it as JSON
printf '{"email":"%s"}' "$EMAIL"