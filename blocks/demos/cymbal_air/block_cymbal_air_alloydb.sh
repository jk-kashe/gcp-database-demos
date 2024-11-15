#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")

source $script_dir/../../utils/lns.sh



files=(
    "$script_dir/demo-cymbal-air-config.yml.tftpl"
    "$script_dir/demo-cymbal-air-00.tf"
    "$script_dir/demo-cymbal-air-20-oauth.tf.step2"
    "$script_dir/demo-cymbal-air-90-vars.tf"
    "$script_dir/demo-cymbal-air-92-oauth-vars.tf.step2"
    "$script_dir/demo-cymbal-air-create-db.sql"
    "$script_dir/step2.sh"
)

source $script_dir/../../utils/block.sh