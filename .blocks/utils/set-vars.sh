#!/bin/bash
#identify all variables without default values in Terraform files
#and prompt for their values

# Get the path of the script (resolving symlinks)
script_path=$(readlink -f "$0")

# Check if the path is a symlink
if [[ -L "$0" ]]; then
  # If it's a symlink, get the directory containing the symlink
  script_dir=$(dirname "$0")
else
  # If it's not a symlink, get the directory of the script itself
  script_dir=$(dirname "$script_path")
fi

# Define the directory containing Terraform files (one level up from the script)
TF_DIR="$script_dir/.."
TFVARS_FILE="${TF_DIR}/terraform.tfvars"
touch $TFVARS_FILE

#Function to get variable value with optional override
get_variable_value() {
  local var_name="$1"
  local default_value=$($script_dir/auto-vars.sh "$var_name")

  if [[ -z "$default_value" ]]; then
    read -p "Enter value for '$var_name': " user_value 
  else
    read -p "Enter value for '$var_name' (default: $default_value): " user_value
    if [[ -z "$user_value" ]]; then
      user_value="$default_value" 
    fi
  fi
  echo "$user_value"
}

# Find all variables without default values
UNDEFINED_VARS=$(awk '/^variable/ {in_block=1; var_name=$2} 
                      in_block && /default/ {has_default=1} 
                      /^}/ && in_block {if (!has_default) print var_name; in_block=0; has_default=0}' "${TF_DIR}"/*.tf)

# Create a temporary tfvars file
TMP_TFVARS=$(mktemp "${TF_DIR}/terraform_tmp.tfvars.XXXXXX")

# Prompt for values and write to the temporary file
for var in $UNDEFINED_VARS; do
    # Remove quotes from the variable name for comparison
    var_without_quotes="${var%\"}"   # Remove closing quote
    var_without_quotes="${var_without_quotes#\"}"  # Remove opening quote

  if ! grep -q "^$var_without_quotes\s*=" "$TFVARS_FILE"; then
    value=$(get_variable_value "$var_without_quotes") # Get value with override option
    echo "$var_without_quotes = \"$value\"" >> "$TMP_TFVARS"
  fi
done

cat "$TMP_TFVARS" >> "$TFVARS_FILE"

# Remove the temporary file
rm "$TMP_TFVARS"