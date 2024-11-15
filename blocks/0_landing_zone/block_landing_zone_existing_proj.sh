#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../utils/lns.sh

files=(
    "$script_dir/00-landing-zone.tf"
    "$script_dir/05-landing-zone-existing-project.tf"
    "$script_dir/10-landing-zone-network.tf"
    "$script_dir/20-landing-zone-apis.tf"
    "$script_dir/30-landing-zone-clientvm.tf"
    "$script_dir/90-landing-zone-vars.tf"
)

source $script_dir/../utils/block.sh