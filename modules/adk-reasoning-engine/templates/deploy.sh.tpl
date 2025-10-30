#!/bin/bash
set -e

# Navigate to the script's directory to ensure relative paths work correctly
cd "$(dirname "$0")"

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
  . | awk '/^AgentEngine created. Resource name: / {print $5}' > ../${output_file_path}
echo ">>> Deployment complete. Output written to ../${output_file_path}"
