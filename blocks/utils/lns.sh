#!/bin/bash

# Function to create or update a symlink in the specified directory
lns() {
  local target_file="$1"
  local dest_dir="$2"

  # Extract filename from the target path
  local link_name=$(basename "$target_file")

  # Construct the full path for the symlink
  local link_path="$dest_dir/$link_name"

  # Check if a link with the same name already exists
  if [[ -L "$link_path" ]]; then
    local existing_target=$(readlink "$link_path")
    if [[ "$existing_target" != "$target_file" ]]; then
      ln -sf "$target_file" "$link_path"
      echo "Symlink '$link_name' updated to point to '$target_file' in '$dest_dir'"
    else
      echo "Symlink '$link_name' already points to '$target_file' in '$dest_dir'"
    fi
  else
    ln -s "$target_file" "$link_path"
    echo "Symlink '$link_name' created, pointing to '$target_file' in '$dest_dir'"
  fi
}