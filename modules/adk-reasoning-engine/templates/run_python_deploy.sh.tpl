#!/bin/bash
set -e

# Determine the absolute path of the script's directory to make all paths reliable,
# as this script is executed by Terraform from a different working directory.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define all paths relative to the script's location.
AGENT_SRC_DIR="$${SCRIPT_DIR}/${agent_src_path}"
VENV_DIR="$${AGENT_SRC_DIR}/.venv"
REQS_FILE="$${AGENT_SRC_DIR}/requirements.txt"
DEPLOY_SCRIPT="$${SCRIPT_DIR}/deploy.py"
OUTPUT_FILE="$${SCRIPT_DIR}/${output_file_path}"

# Set up a virtual environment and install dependencies.
echo ">>> Setting up Python virtual environment in $${VENV_DIR}..."
python3 -m venv "$${VENV_DIR}"
source "$${VENV_DIR}/bin/activate"
pip install -r "$${REQS_FILE}"
pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111"

# Deploy to Agent Engine using the Python script from the module root.
echo ">>> Deploying to Agent Engine via Python script..."
python "$${DEPLOY_SCRIPT}" \
  --project "${project_id}" \
  --region "${region}" \
  --staging_bucket "gs://${staging_bucket_name}" \
  --display_name "${agent_display_name}" \
  --agent_app_path "$${AGENT_SRC_DIR}" \
  --output_file "$${OUTPUT_FILE}"

echo ">>> Python deployment script finished."

