#!/bin/bash

# Get the source directory, destination directory, and output file name from command-line arguments
source_dir="$1"
dest_dir="$2"
output_file_name="$3"

# Initialize a variable to control whether to include optional files
include_optional=false

# Parse optional flags
while [[ $# -gt 3 ]]; do
  case "$4" in
    -o|--optional)
      include_optional=true
      shift
      ;;
    *)
      echo "Unknown option: $4"
      exit 1
      ;;
  esac
done

# Check if required arguments are provided
if [[ -z "$source_dir" || -z "$dest_dir" || -z "$output_file_name" ]]; then
  echo "Usage: $0 <source_directory> <destination_directory> <output_file_name> [-o|--optional]"
  exit 1
fi

# Define the full path to the output file
output_file="$dest_dir/$output_file_name"
# Define the full path to the variables file
vars_file="$dest_dir/variables.tf"

# Create the destination directory if it doesn't exist
mkdir -p "$dest_dir"

# Clear the output files if they already exist
#> "$output_file"
#> "$vars_file"

# Function to append a file to the output file
append_file() {
  local file="$1"
  local target_file="$2"
  echo "Appending: $file to $target_file"
  cat "$file" >> "$target_file"
  echo "" >> "$target_file"  # Add a newline
}

# Copy templates directory (only .tftpl files)
echo "Copying templates directory from $source_dir to $dest_dir/templates"
mkdir -p "$dest_dir/templates"
find "$source_dir/templates" -name "*.tftpl" -exec cp {} "$dest_dir/templates" \;

# Copy 'files' directory if it exists
if [ -d "$source_dir/files" ]; then
  echo "Copying files directory from $source_dir to $dest_dir/files"
  mkdir -p "$dest_dir/files"
  find "$source_dir/files" -type f -exec cp {} "$dest_dir/files" \;
fi

# Copy other files, excluding .tf, .tftpl, and directories
echo "Copying necessary files from $source_dir to $dest_dir/files"
mkdir -p "$dest_dir/files"
find "$source_dir" -maxdepth 1 -not -path "$source_dir/templates" -a -type f \( -not -name "*.tf" -a -not -name "*.tftpl" \) -exec cp {} "$dest_dir/files" \;


# Find all .tf files in the source directory
while IFS=  read -r -d $'\0'; do
    file="$REPLY"
    # Check if the file is optional and if we should include optional files
    if [[ "$file" == *"optional"* ]] && ! $include_optional; then
        echo "Skipping optional file: $file"
        continue
    fi

    # Determine the target file based on whether the filename contains "vars"
    if [[ "$file" == *"vars"* ]]; then
        target_file="$vars_file"
    else
        target_file="$output_file"
    fi

    append_file "$file" "$target_file"
done < <(find "$source_dir"  -maxdepth 1 -name "*.tf" -print0)

echo "Combined files into: $output_file"
echo "Combined 'vars' files into: $vars_file"