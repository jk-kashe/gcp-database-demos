
# Get the destination directory from the command-line argument
dest_dir="$1"

# Check if a destination directory is provided
if [[ -z "$dest_dir" ]]; then
  echo "Usage: $0 <destination_directory>"
  exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$dest_dir"

# Loop through the array of files
for file in "${files[@]}"; do
  lns "$file" "$dest_dir"
done