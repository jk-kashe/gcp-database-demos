#!/bin/bash

# Function to create or update a symlink in the specified directory
#!/bin/bash

# Function to create or update a symlink in the specified directory
lns() {
  local target_file="$1"
  local dest_dir="$2"

  # Extract filename from the target path
  local link_name=$(basename "$target_file")

  # Construct the full path for the symlink
  local link_path="$dest_dir/$link_name"

  # Calculate the relative path from the destination directory to the target file
  local relative_path=$(realpath --relative-to="$dest_dir" "$target_file")

  # Check if a link with the same name already exists
  if [[ -L "$link_path" ]]; then
    local existing_target=$(readlink "$link_path")
    if [[ "$existing_target" != "$relative_path" ]]; then
      ln -sf "$relative_path" "$link_path"
      echo "Symlink '$link_name' updated to point to '$relative_path' in '$dest_dir'"
    else
      echo "Symlink '$link_name' already points to '$relative_path' in '$dest_dir'"
    fi
  else
    ln -s "$relative_path" "$link_path"
    echo "Symlink '$link_name' created, pointing to '$relative_path' in '$dest_dir'"
  fi
}

lns $1 $2