#!/bin/bash
#
# This script updates the ORDS settings.xml to configure CORS for a Cloud Run URL.
# It automatically checks for and installs dependencies ('xmlstarlet').
#

set -e

# --- Helper Functions ---
info() {
    echo "INFO: $1"
}

error() {
    echo "ERROR: $1" >&2
    exit 1
}

# --- Pre-flight Checks & Dependency Installation ---
check_and_install_deps() {
    info "Checking for required dependencies..."

    # Check for gcloud (cannot be auto-installed)
    if ! command -v gcloud &> /dev/null; then
        error "'gcloud' could not be found. Please ensure the Google Cloud SDK is installed and in your PATH."
    fi

    # Check for xmlstarlet and install if not present
    if command -v xmlstarlet &> /dev/null; then
        info "'xmlstarlet' is already installed."
    else
        info "'xmlstarlet' not found. Attempting to install..."
        if [[ "$(uname)" == "Linux" ]]; then
            # Check for sudo privileges
            local sudo_cmd=""
            if [[ $EUID -ne 0 ]]; then
                if ! command -v sudo &> /dev/null; then
                     error "'sudo' command not found, and script is not run as root. Please install 'xmlstarlet' manually."
                fi
                sudo_cmd="sudo"
            fi
            info "Detected Linux. Using apt-get to install xmlstarlet."
            $sudo_cmd apt-get update -y
            $sudo_cmd apt-get install -y xmlstarlet
        elif [[ "$(uname)" == "Darwin" ]]; then
            if command -v brew &> /dev/null; then
                info "Detected macOS. Using Homebrew to install xmlstarlet."
                brew install xmlstarlet
            else
                error "Homebrew not found on macOS. Please install Homebrew, or install 'xmlstarlet' manually."
            fi
        else
            error "Unsupported OS for auto-installation: $(uname). Please install 'xmlstarlet' manually."
        fi

        # Verify installation
        if ! command -v xmlstarlet &> /dev/null; then
            error "Failed to install 'xmlstarlet'. Please install it manually and re-run."
        fi
        info "'xmlstarlet' installed successfully."
    fi

    info "All dependencies are satisfied."
}

# --- Main Logic ---
main() {
    # 1. Validate Input
    if [ "$#" -ne 2 ]; then
        error "Usage: $0 <gcs_bucket_name> <cloud_run_url>"
    fi

    local gcs_bucket_name=$1
    local cloud_run_url=$2
    local settings_file="global/settings.xml"
    local temp_settings_file
    temp_settings_file=$(mktemp)

    # 2. Download settings.xml from GCS
    info "Downloading $settings_file from gs://$gcs_bucket_name..."
    if ! gcloud storage cp "gs://$gcs_bucket_name/$settings_file" "$temp_settings_file"; then
        error "Failed to download settings.xml from bucket '$gcs_bucket_name'. The bucket or file may not exist yet."
    fi

    # 3. Prepare the URL (remove trailing slash if it exists)
    local clean_url
    clean_url=$(echo "$cloud_run_url" | sed 's:/*$::')

    # 4. Idempotently update CORS settings using XMLStarlet
    info "Updating CORS settings with URL: $clean_url"

    declare -A settings_to_update
    settings_to_update["cors.allowedOrigins"]="$clean_url"
    settings_to_update["security.externalSessionTrustedOrigins"]="$clean_url"

    for key in "${!settings_to_update[@]}"; do
        local value="${settings_to_update[$key]}"
        info "Processing setting: $key"
        
        # First, delete any existing entry for the key to ensure no duplicates
        xmlstarlet ed -L -d "/properties/entry[@key='$key']" "$temp_settings_file"
        
        # Second, add the new, updated entry
        xmlstarlet ed -L -s "/properties" -t elem -n "entry" -v "$value" \
            -i "/properties/entry[not(@key)]" -t attr -n "key" -v "$key" \
            "$temp_settings_file"
    done

    # 5. Upload the modified settings.xml back to GCS
    info "Uploading modified $settings_file to gs://$gcs_bucket_name..."
    gcloud storage cp "$temp_settings_file" "gs://$gcs_bucket_name/$settings_file"

    # 6. Clean up
    rm "$temp_settings_file"

    info "CORS configuration updated successfully."
}

# --- Execution ---
check_and_install_deps
main "$@"
