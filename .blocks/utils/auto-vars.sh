#!/bin/bash

# Function to get a valid alloydb trial region
get_valid_region() {
  local current_region=$(gcloud config get-value compute/region)

  # If region is already valid, return it
  case "$current_region" in
    us-central1 | northamerica-northeast1 | asia-east1 | asia-northeast2 | asia-south2 | asia-southeast1 | australia-southeast2 | europe-north1 | europe-west1 | europe-west4)
      echo "$current_region"
      return
      ;;
  esac

  # If region is invalid, try to match the prefix
  case "$current_region" in
    us-*)
      echo "us-central1"
      ;;
    northamerica-*)
      echo "northamerica-northeast1"
      ;;
    asia-*)
      # Pick a random "asia-" region
      local asia_regions=(asia-east1 asia-northeast2 asia-south2 asia-southeast1)
      echo "${asia_regions[$((RANDOM % ${#asia_regions[@]}))]}"
      ;;
    europe-*)
      # Pick a random "europe-" region
      local europe_regions=(europe-north1 europe-west1 europe-west4)
      echo "${europe_regions[$((RANDOM % ${#europe_regions[@]}))]}"
      ;;
    australia-*)
      echo "australia-southeast2"
      ;;
    *)
      echo "europe-west1"
      # below idea has issues on quicklabs, defaulting to us-central1 now
      # If no region is set or prefix doesn't match, pick a completely random region
      #local all_regions=(us-central1 northamerica-northeast1 asia-east1 asia-northeast2 asia-south2 asia-southeast1 australia-southeast2 europe-north1 europe-west1 europe-west4)
      #echo "${all_regions[$((RANDOM % ${#all_regions[@]}))]}"
      ;;
  esac
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
    echo "b"
    ;;
demo_app_support_email)
    # Get the first email address from the gcloud auth list
    gcloud auth list --format="value(account)" | head -n 1 
    ;;
*)
    echo ""
    ;;
esac