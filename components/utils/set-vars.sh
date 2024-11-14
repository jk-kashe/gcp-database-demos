#!/bin/bash

TF_DIR="."
TFVARS_FILE="${TF_DIR}/terraform.tfvars"
touch "$TFVARS_FILE"

# Find all variables without default values
UNDEFINED_VARS=()
for tf_file in "${TF_DIR}"/*.tf; do
    while IFS= read -r line; do
        if [[ "$line" == "variable "* ]] && [[ ! "$line" =~ "default" ]]; then
            var_name=$(echo "$line" | awk '{print $2}')
            UNDEFINED_VARS+=("$var_name")
        fi
    done < "$tf_file"
done

# Create a temporary tfvars file
TMP_TFVARS=$(mktemp "${TF_DIR}/terraform_tmp.tfvars.XXXXXX")

# Prompt for values and write to the temporary file
for var in "${UNDEFINED_VARS[@]}"; do
    # Check if the variable is already defined in tfvars
    if ! grep -q "^$var\s*=" "$TFVARS_FILE"; then
        read -p "Enter value for '$var': " value
        echo "$var = \"$value\"" >> "$TMP_TFVARS"
    fi
done

cat "$TMP_TFVARS" >> "$TFVARS_FILE"

# Remove the temporary file
rm "$TMP_TFVARS"