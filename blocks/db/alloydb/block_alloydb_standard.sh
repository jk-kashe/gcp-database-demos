#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh



files=(
    "$script_dir/92-landing-zone-clivm-vars.tf"
    "$script_dir/db-alloydb-00-apis.tf"
    "$script_dir/db-alloydb-10-cluster.tf"
    "$script_dir/db-alloydb-20-instance.tf "
    "$script_dir/db-alloydb-30-clientvm.tf"
    "$script_dir/db-alloydb-90-vars.tf"
    "$script_dir/db-alloydb-95a-standard-instance-vars.tf"
    "$script_dir/db-alloydb-pgauth.env.tftpl"
)

source $script_dir/../../utils/block.sh