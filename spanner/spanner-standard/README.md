# Spanner Standard

This repository provides deployment scripts for Spanner Standard


## Getting Started

1. **Prerequisites:**
    * GCP Environment with sufficiently broad permissions to create various resources

2. **Deployment:**
    * Create a project to host your deployment. We recommend an empty project to avoid any unforseen issues.
    * Open Cloud Shell and set your target project as the current project (this guide assumes you are using cloud shell!)
    * Run these commands:
    ```
    git clone https://github.com/jk-kashe/gcp-database-demos
    cd gcp-database-demos/spanner/spanner-standard
    make apply
    ```
    * Deployment script ask you to provide variable values. Most variables should be auto-populated, but check they are correct. It's assumed you have the knowledge of GCP to find the correct values!


 # License

This project is licensed under the [Apache License 2.0] 

## Disclaimer

This project is intended for demonstration purposes only. It is not an officially supported Google product and should not be used in production environments without careful consideration and appropriate modifications.