#!/bin/bash
set -e

# Navigate to the script's directory to ensure relative paths work correctly
cd "$(dirname "$0")"

# Set up a virtual environment and install dependencies
echo ">>> Setting up Python virtual environment in src..."
cd ${agent_src_path}
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Also need the vertexai sdk with adk extras
pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111"

# Deploy to Agent Engine using the Python script
echo ">>> Deploying to Agent Engine via Python script..."
python ../deploy.py \
  --project "${project_id}" \
  --region "${region}" \
  --staging_bucket "gs://${staging_bucket_name}" \
  --display_name "${agent_display_name}" \
  --output_file "../${output_file_path}"

echo ">>> Python deployment script finished."

