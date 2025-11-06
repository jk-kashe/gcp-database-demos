# Project TODO List

This file outlines the necessary improvements to fully automate the APEX/ORDS deployment and make it more robust.

## 1. Automate APEX Static File Configuration (CDN with Fallback)

The current manual process of setting the APEX image prefix is fragile. We need to automate this with a reliable fallback mechanism.

-   **Primary Goal:** Use the official Oracle CDN for APEX static files by setting the `IMAGE_PREFIX` parameter.
-   **Challenge:** The specific version of APEX installed by the scripts may not have a corresponding CDN URL available immediately upon release.
-   **Proposed Solution:**
    1.  In Terraform, after the Oracle VM is provisioned, determine the exact APEX version that was installed.
    2.  Construct the expected CDN URL based on this version.
    3.  Add a `local-exec` or similar provisioner that tests if this URL is valid (e.g., using `curl` to check for a `200 OK` response on a known static file).
    4.  **If the CDN is available:** Run the SQL command to set the `IMAGE_PREFIX` to the CDN URL.
    5.  **If the CDN is NOT available (Fallback):**
        -   Copy the static `images` directory from the VM to the GCS bucket.
        -   Modify the Cloud Build process (`cloudbuild.yaml`) to copy these images from GCS into the Cloud Run container image.
        -   Run the SQL command to set the `IMAGE_PREFIX` to the default local path (`/i/`).

## 2. Automate CORS Configuration for Cloud Run

The CORS error requires manual steps because the Cloud Run URL isn't known when the initial configuration is created. This should be automated.

-   **Goal:** Automatically add the correct Cloud Run URL to the `security.externalSessionTrustedOrigins` and `cors.allowedOrigins` keys in the `settings.xml` file.
-   **Challenge:** The Cloud Run URL is generated late in the deployment process, after the initial `settings.xml` has already been created and placed in the GCS bucket.
-   **Proposed Solution:**
    1.  After the `google_cloud_run_v2_service` resource is successfully created in Terraform, add a new `null_resource` with a `local-exec` provisioner.
    2.  This provisioner will depend on the Cloud Run service, ensuring it runs after the URL is available.
    3.  The `local-exec` script will:
        a. Take the Cloud Run service URL as an input variable.
        b. Use `gcloud storage cp` to download the `settings.xml` file from the GCS bucket to the local machine running Terraform.
        c. Use a script or tool (`sed`, `awk`, etc.) to parse the XML and insert/update the two required `<entry>` keys with the Cloud Run URL (ensuring no trailing slash).
        d. Use `gcloud storage cp` to upload the modified `settings.xml` file back to the GCS bucket, overwriting the original.
    4.  Add a final `null_resource` that runs a `gcloud run deploy` command with a dummy environment variable (e.g., `TF_UPDATE_TIMESTAMP`). This will force a new revision of the Cloud Run service to be deployed, making it read the updated configuration from the GCS bucket.