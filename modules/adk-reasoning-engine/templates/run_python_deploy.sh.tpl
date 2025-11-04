#!/bin/bash
set -e

# Set up a virtual environment inside the agent source path without changing the current directory
echo ">>> Setting up Python virtual environment in ${agent_src_path}..."
python3 -m venv ${agent_src_path}/.venv
source ${agent_src_path}/.venv/bin/activate
pip install -r ${agent_src_path}/requirements.txt
# Also need the vertexai sdk with adk extras
pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111"

# Deploy to Agent Engine using the Python script from the module root
echo ">>> Deploying to Agent Engine via Python script..."
python deploy.py \
  --project "${project_id}" \
  --region "${region}" \
  --staging_bucket "gs://${staging_bucket_name}" \
  --display_name "${agent_display_name}" \
  --agent_app_path "${agent_src_path}" \
  --output_file "${output_file_path}"

echo ">>> Python deployment script finished."

