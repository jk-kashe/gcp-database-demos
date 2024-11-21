#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh

files=(
    "$script_dir/92-landing-zone-clivm-vars.tf"
    "$script_dir/db-alloydb-00-apis.tf"
    "$script_dir/db-alloydb-10-cluster.tf"
    "$script_dir/db-alloydb-20-instance.tf"
    "$script_dir/db-alloydb-30-clientvm.tf"
    "$script_dir/db-alloydb-40-ai.tf"    
    "$script_dir/db-alloydb-90-vars.tf"
    "$script_dir/db-alloydb-pgauth.env.tftpl"
    "$script_dir/db-alloydb-ai.sql"
)

# Ask the user what they want to provision
read -r -p "Provision AlloyDB free trial or standard? [trial/standard]: " project_type

# Validate the input and set default to 
if [[ "$project_type" == "trial" || -z "$project_type" ]]; then
  echo "Configuring AlloyDB trial..."
  files+=(
    "$script_dir/db-alloydb-95b-trial-instance-vars.tf"
  )
elif [[ "$project_type" == "standard"  ]]; then 
  echo "Configuring AlloyDb Standard..."
  files+=(
    "$script_dir/db-alloydb-95a-standard-instance-vars.tf"
  )
else
  echo "Invalid input. Please enter 'trial' or 'standard'."
  exit 1
fi


source $script_dir/../../utils/block.sh