#!/bin/bash

# Function to get a valid alloydb trial region
get_valid_region() {
  local current_region=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
  echo "$current_region"
  return
  ##old code is now unreachable
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

get_agentspace_alloydb_path() {
  # Create a temporary file to store the downloaded content
  tempfile=$(mktemp)

  # Download the file from the specified URL
  curl -sLo "$tempfile" "https://storage.googleapis.com/alloydb-vector-demo/agentspace/alloydb-instances.txt"

  # Check if the download was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download alloydb-instances.txt" >&2
    rm "$tempfile"
    echo ""
    return 1
  fi

  # Check if the downloaded file is empty
  if [ ! -s "$tempfile" ]; then
    echo "Error: Downloaded alloydb-instances.txt is empty" >&2
    rm "$tempfile"
    echo ""
    return 1
  fi

  # Randomly pick one line from the file and print it
  # Use shuf (if available) for random line selection
  # If shuf is not available (like on older macOS), use awk with random() piped to head -n 1
  if command -v shuf &> /dev/null; then
    shuf -n 1 "$tempfile"
  else
    awk 'BEGIN { srand() } { if (rand() < 1/NR) line = $0 } END { print line }' "$tempfile" | head -n 1
  fi

  # Clean up the temporary file
  rm "$tempfile"
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
    full_zone=$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-zone])')
    echo "${full_zone##*-}"
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
agentspace_alloydb_path)
    get_agentspace_alloydb_path
    ;;
*)
    echo ""
    ;;
esac
