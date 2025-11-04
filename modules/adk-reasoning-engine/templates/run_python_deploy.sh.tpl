#!/bin/bash
set -e

# This script runs from the root of the module.
# It treats 'src' as a package.

# Set up a virtual environment and install dependencies inside the 'src' directory
echo ">>> Setting up Python virtual environment in src..."
python3 -m venv src/.venv
source src/.venv/bin/activate
pip install -r src/requirements.txt
pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111"

# Deploy to Agent Engine using the Python script from the module root.
# This ensures that 'from src.agent...' works correctly.
echo ">>> Deploying to Agent Engine via Python script..."
python deploy.py \
  --project "${project_id}" \
  --region "${region}" \
  --staging_bucket "gs://${staging_bucket_name}" \
  --display_name "${agent_display_name}" \
  --agent_app_path "src" \
  --output_file "${output_file_path}"

echo ">>> Python deployment script finished."

