#!/bin/bash
set -e

# Navigate to the script's directory to ensure relative paths work correctly
cd "$(dirname "$0")"

# Navigate to the agent source directory to reuse the venv
cd src

# Check if the virtual environment exists, if not, create and install deps
if [ ! -d ".venv" ]; then
    echo ">>> Virtual environment not found. Creating and installing dependencies..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt > /dev/null
    pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111" > /dev/null
else
    echo ">>> Reusing existing Python virtual environment..."
    source .venv/bin/activate
fi

# Undeploy via the Python script
echo ">>> Undeploying Agent Engine via Python script..."
python undeploy.py --resource_name "${reasoning_engine_resource_name}"

echo ">>> Python undeploy script finished."