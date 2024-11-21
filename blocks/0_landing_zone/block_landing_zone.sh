#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../utils/lns.sh

files=(
    "$script_dir/00-landing-zone.tf"
    "$script_dir/10-landing-zone-network.tf"
    "$script_dir/20-landing-zone-apis.tf"
    "$script_dir/30-landing-zone-clientvm.tf"
    "$script_dir/90-landing-zone-vars.tf"
)


# Ask the user if the destination is a new or existing project
read -r -p "Is destination a new or existing project? [new/existing]: " project_type

# Validate the input and set default to "new"
if [[ "$project_type" == "existing" ]]; then
  echo "Deploying to an existing project..."
  files+=(
    "$script_dir/05-landing-zone-existing-project.tf"
  )
elif [[ "$project_type" == "new" || -z "$project_type" ]]; then 
  echo "Deploying to a new project..."
  files+=(
    "$script_dir/05-landing-zone-new-project.tf"
  )
else
  echo "Invalid input. Please enter 'new' or 'existing'."
  exit 1
fi

source $script_dir/../utils/block.sh