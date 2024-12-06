#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh

files=(
    "$script_dir/92-landing-zone-clientvm-vars.tf"
    "$script_dir/db-spanner-00-apis.tf"
    "$script_dir/db-spanner-10-instance.tf"
    "$script_dir/db-spanner-15-dataflow-roles.tf"
    "$script_dir/db-spanner-30-clientvm.tf"
    "$script_dir/db-spanner-90-vars.tf"
    "$script_dir/db-spanner.env.tftpl"
 )

 # Ask the user what they want to provision
read -r -p "Provision Spanner standard or enterprise? [standard/enterprise]: " project_type

# Validate the input and set default to 
if [[ "$project_type" == "standard" || -z "$project_type" ]]; then
  echo "Configuring Spanner standard..."
  files+=(
    "$script_dir/db-spanner-95a-standard-edition-vars.tf"
  )
elif [[ "$project_type" == "enterprise"  ]]; then 
  echo "Configuring Spanner enterprise..."
  files+=(
    "$script_dir/db-alloydb-95b-enterprise-edition-vars.tf"
  )
else
  echo "Invalid input. Please enter 'standard' or 'enterprise'."
  exit 1
fi

source $script_dir/../../utils/block.sh