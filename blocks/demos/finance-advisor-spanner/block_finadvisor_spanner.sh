#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh



files=(
    "$script_dir/../common/demo-common-registry-repo.tf"
    "$script_dir/demo-finance-advisor-spanner.tf"
    "$script_dir/demo-finance-advisor-import.tf"
    "$script_dir/demo-finance-advisor-extra-ddl.tf"
)

source $script_dir/../../utils/block.sh