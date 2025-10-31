#!/bin/bash
# This script will run after the main APEX installation.
# It dynamically fetches available CDN versions from Oracle's website,
# compares them to the installed APEX version, and configures the best match.

# Function to execute SQL commands as SYSDBA in the PDB
run_sql_as_sys() {
  # Use a pipe to send commands to sqlplus
  echo "
    ALTER SESSION SET CONTAINER = FREEPDB1;
    SET HEADING OFF FEEDBACK OFF PAGESIZE 0;
    $1
    /
    COMMIT;
    EXIT;
  " | sqlplus -s / as sysdba
}

# 1. Get installed APEX version and extract only the version number
APEX_VERSION=$(run_sql_as_sys "SELECT version_no FROM apex_release;" | grep -oE '[0-9]+(\.[0-9]+)+')
echo "Detected APEX version: $APEX_VERSION"

if [ -z "$APEX_VERSION" ]; then
  echo "Could not determine APEX version. Skipping CDN configuration."
  exit 0
fi

# 2. Fetch and parse available CDN versions from the downloads page
DOWNLOADS_URL="https://www.oracle.com/tools/downloads/apex-downloads/"
echo "Fetching available CDN versions from $DOWNLOADS_URL..."

# Use curl to get the page content, grep with Perl regex to find 'cdn/apex/X.Y.Z',
# extract just the version number, sort uniquely, and then reverse version-sort to get newest first.
AVAILABLE_CDN_VERSIONS=$(curl -s $DOWNLOADS_URL | \
  grep -oP 'cdn/apex/\K\d+\.\d+\.\d+' | \
  sort -u | \
  sort -rV)

if [ -z "$AVAILABLE_CDN_VERSIONS" ]; then
    echo "Could not fetch or parse CDN versions from Oracle's website. Defaulting to /i/."
    curl -X PUT --data "ERROR: Failed to fetch CDN list." -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes/apex/cdn_status"
    exit 0
fi

echo "Found available CDN versions:"
echo "$AVAILABLE_CDN_VERSIONS"

# 3. Find the best matching CDN version
BEST_MATCH_VERSION=""
for CDN_VERSION in $AVAILABLE_CDN_VERSIONS; do
  # Check if CDN_VERSION is less than or equal to APEX_VERSION.
  # We do this by combining them, sorting with version sort (-V), and checking which one comes first.
  LOWER_VERSION=$(printf "%s\n%s" "$APEX_VERSION" "$CDN_VERSION" | sort -V | head -n 1)
  
  if [ "$LOWER_VERSION" == "$CDN_VERSION" ]; then
    # This means CDN_VERSION <= APEX_VERSION, so it's a candidate.
    # Since the list is sorted newest first (sort -rV), the first match is the best one.
    BEST_MATCH_VERSION=$CDN_VERSION
    break
  fi
done

# 4. Configure CDN if a match was found
if [ -n "$BEST_MATCH_VERSION" ]; then
  CDN_URL="https://static.oracle.com/cdn/apex/$BEST_MATCH_VERSION/"
  echo "Found best match CDN version: $BEST_MATCH_VERSION. Using URL: $CDN_URL"
  
  # Set the image prefix in the database
  run_sql_as_sys "BEGIN APEX_INSTANCE_ADMIN.SET_PARAMETER('IMAGE_PREFIX', '$CDN_URL'); END;"
  
  echo "Successfully set IMAGE_PREFIX to $CDN_URL"
  
  # Verify the change
  echo "Verifying IMAGE_PREFIX in database:"
  run_sql_as_sys "SELECT APEX_INSTANCE_ADMIN.GET_PARAMETER('IMAGE_PREFIX') FROM DUAL;"

  # Report success to guest attributes for visibility
  curl -X PUT --data "SUCCESS: $CDN_URL" -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes/apex/cdn_status"
  exit 0
else
  echo "No suitable APEX CDN found from fetched list for version $APEX_VERSION. Defaulting to local /i/."
  # Report fallback to guest attributes
  curl -X PUT --data "FALLBACK: /i/" -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes/apex/cdn_status"
fi
