#!/bin/bash

# Function to get a valid alloydb trial region
get_valid_region() {
  # Try to get the default region from gcloud config
  local current_region=$(gcloud config get-value compute/region 2>/dev/null)

  # If the region is not set in the config, get it from the project metadata
  if [ -z "$current_region" ]; then
    current_region=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)
  fi

  # If region is still not set, default to a valid one
  if [ -z "$current_region" ]; then
    current_region="europe-west2"
  fi

  echo "$current_region"
}



# Function to handle different input strings
input="$1"

case "$input" in
demo_project_id)
    gcloud config get-value project
    ;;
billing_account_id)
    gcloud beta billing projects describe $(gcloud config get-value project) --format="value(billingAccountName)" | sed 's/billingAccounts\///'
    ;;
region)
    get_valid_region
    ;;
zone)
    region=$(get_valid_region)
    zone_name=$(gcloud compute zones list --filter="region=$region" --format='value(name)' | head -n 1)
    echo "${zone_name##*-}"
    ;;
demo_app_support_email)
    # Get the first email address from the gcloud auth list
    gcloud auth list --format="value(account)" | head -n 1 
    ;;
finance_advisor_commit_id)
    echo "04518003381346a1d08e4c3f1257dbe6049651a0"
    ;;
agentspace_retrieval_service_repo_revision)
    echo "main"
    ;;

*)
    echo ""
    ;;
esac
