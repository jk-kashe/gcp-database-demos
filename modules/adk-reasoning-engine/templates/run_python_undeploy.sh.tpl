#!/bin/bash
set -e

# Determine the absolute path of the script's directory to make all paths reliable.
SCRIPT_DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define paths
VENV_DIR="$${SCRIPT_DIR}/.venv"
AGENT_SRC_DIR="$${SCRIPT_DIR}/src"
REQS_FILE="$${AGENT_SRC_DIR}/requirements.txt"
UNDEPLOY_SCRIPT="$${AGENT_SRC_DIR}/undeploy.py"

# Check if the virtual environment exists, if not, create and install deps
if [ ! -d "$${VENV_DIR}" ]; then
    echo ">>> Virtual environment not found. Creating and installing dependencies..."
    python3 -m venv "$${VENV_DIR}"
    source "$${VENV_DIR}/bin/activate"
    pip install -r "$${REQS_FILE}" > /dev/null
    pip install "google-cloud-aiplatform[adk,agent_engines]>=1.111" > /dev/null
else
    echo ">>> Reusing existing Python virtual environment..."
    source "$${VENV_DIR}/bin/activate"
fi

# Undeploy via the Python script
echo ">>> Undeploying Agent Engine via Python script..."
python "$${UNDEPLOY_SCRIPT}" --resource_name "${reasoning_engine_resource_name}"

echo ">>> Python undeploy script finished."