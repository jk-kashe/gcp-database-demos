#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh

files=(
    "$script_dir/92-landing-zone-clientvm-vars.tf"
    "$script_dir/db-spanner-00-apis.tf"
    "$script_dir/db-spanner-10-instance.tf"
    "$script_dir/db-spanner-30-clientvm.tf"
    "$script_dir/db-spanner-95a-standard-edition-vars.tf"
    "$script_dir/db-spanner.env.tftpl"
 )

source $script_dir/../../utils/block.sh