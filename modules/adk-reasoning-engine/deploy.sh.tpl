#!/bin/bash
set -e

# Navigate to the agent source directory
cd ${agent_src_path}

# Set up a virtual environment and install dependencies
echo ">>> Setting up Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Deploy to Agent Engine and capture output
echo ">>> Deploying to Agent Engine..."
adk deploy agent_engine \
  --project ${project_id} \
  --region ${region} \
  --staging_bucket gs://${staging_bucket_name} \
  --display_name "${agent_display_name}" \
  . | grep "projects/.*/locations/.*/reasoningEngines/.*" > ${output_file_path}
echo ">>> Deployment complete. Output written to ${output_file_path}"
