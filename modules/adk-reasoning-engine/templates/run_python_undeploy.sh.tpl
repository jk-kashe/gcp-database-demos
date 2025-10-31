#!/bin/bash
set -e

# Navigate to the script's directory to ensure relative paths work correctly
cd "$(dirname "$0")"

# Set up a virtual environment and install dependencies quietly
echo ">>> Setting up Python virtual environment for undeploy..."
python3 -m venv .venv-undeploy
source .venv-undeploy/bin/activate
pip install "google-cloud-aiplatform>=1.111" > /dev/null

# Undeploy via the Python script
echo ">>> Undeploying Agent Engine via Python script..."
python undeploy.py --resource_name "${reasoning_engine_resource_name}"

echo ">>> Python undeploy script finished."
