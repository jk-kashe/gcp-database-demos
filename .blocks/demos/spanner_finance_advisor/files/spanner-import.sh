#!/bin/bash

# --- Configuration ---
JOB_NAME_PREFIX="spanner-finadvisor-import"  # Prefix of the Dataflow job name
MAX_RETRIES=5       # Maximum number of retries for job execution
MAX_WAIT_TIME=900   # Seconds (15 minutes)
POLL_INTERVAL=30    # Seconds

# --- Function to check the Dataflow job status ---
check_dataflow_job_status() {
  local job_id="$1"
  local status

  status=$(gcloud dataflow jobs describe "$job_id" --region="$REGION" --format="value(currentState)")
  if [[ $? -ne 0 ]]; then
    echo "Error: Could not get status for job ID '$job_id'." >&2
    return 1
  fi

  echo "$status"
}

# --- Function to submit the Dataflow job ---
submit_dataflow_job() {
  local job_id

  job_id=$(gcloud dataflow jobs run "$JOB_NAME_PREFIX" \
    --gcs-location gs://dataflow-templates-"$REGION"/latest/GCS_Avro_to_Cloud_Spanner \
    --staging-location="$STAGING_LOCATION" \
    --service-account-email="$SERVICE_ACCOUNT_EMAIL" \
    --region "$REGION" \
    --network "$NETWORK" \
    --parameters "instanceId=$INSTANCE_ID,databaseId=$DATABASE_ID,inputDir=$INPUT_DIR" \
    --format="value(id)" 2>&1)

  if [[ $? -ne 0 ]]; then
    echo "Error: Could not submit Dataflow job." >&2
    echo "$job_id" >&2 # Print the error message from gcloud
    return 1
  fi

  echo "$job_id"
}

# --- Main Execution ---
RETRY_COUNT=0
JOB_ID=""

while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  # Submit the job if it's the first attempt or a retry after a job failure
  if [[ $RETRY_COUNT -eq 0 || "$STATUS" == "JOB_STATE_FAILED" ]]; then
    if [[ $RETRY_COUNT -gt 0 ]]; then
      echo "Retrying Dataflow job submission (attempt $((RETRY_COUNT + 1)))..."
      sleep 60 # Wait for 60 seconds before retrying
    fi

    JOB_ID=$(submit_dataflow_job)
    if [[ $? -ne 0 ]]; then
      exit 1 # Exit if job submission fails
    fi
  fi

  # Monitor the job status
  START_TIME=$SECONDS
  STATUS="JOB_STATE_UNKNOWN" # Initialize STATUS to handle the first iteration

  while [[ $(($SECONDS - $START_TIME)) -lt $MAX_WAIT_TIME ]]; do
    STATUS=$(check_dataflow_job_status "$JOB_ID")
    if [[ $? -ne 0 ]]; then
      exit 1
    fi

    case "$STATUS" in
    "JOB_STATE_DONE")
      echo "Dataflow job '$JOB_ID' completed successfully."
      exit 0
      ;;
    "JOB_STATE_FAILED")
      echo "Dataflow job '$JOB_ID' failed. Retrying..."
      RETRY_COUNT=$((RETRY_COUNT + 1))
      break # Break out of the inner monitoring loop to retry submission
      ;;
    "JOB_STATE_CANCELLED" | "JOB_STATE_UPDATED" | "JOB_STATE_DRAINED")
      echo "Dataflow job '$JOB_ID' was cancelled, updated, or drained."
      exit 1
      ;;
    *)
      echo "Dataflow job '$JOB_ID' status: $STATUS. Waiting for $POLL_INTERVAL seconds..."
      sleep "$POLL_INTERVAL"
      ;;
    esac
  done

  # If the job didn't succeed and we've reached here, it's either a timeout or a failure
  if [[ "$STATUS" != "JOB_STATE_DONE" ]]; then
    if [[ $(($SECONDS - $START_TIME)) -ge $MAX_WAIT_TIME ]]; then
      echo "Timeout: Dataflow job '$JOB_ID' did not complete within $MAX_WAIT_TIME seconds."
    fi

    # If we haven't reached max retries, increment the counter (for job failure case, it's already incremented)
    if [[ "$STATUS" != "JOB_STATE_FAILED" ]]; then
      RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
  fi
done

echo "Dataflow job failed after $MAX_RETRIES retries."
exit 1