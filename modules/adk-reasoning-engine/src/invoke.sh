#!/bin/bash
set -e

# Check if a prompt was provided
if [ -z "$1" ]; then
  echo "Usage: $0 \"<your natural language query>\""
  exit 1
fi

# Activate the virtual environment and run the python script
# Pass all command-line arguments to the python script
source ./.venv/bin/activate
python invoke.py "$@"
