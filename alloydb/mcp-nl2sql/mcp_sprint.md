# MCP-NL2SQL Demo Sprint Plan

## Goal
Create a compelling demo showcasing the natural language querying capabilities of AlloyDB AI using the MCP Server and the Pagila sample database.

## Current Status
-   Infrastructure is defined in a modularized Terraform project.
-   AlloyDB cluster and a client VM are provisioned.
-   The `pagila` sample database is deployed to the AlloyDB cluster.
-   The `nl2sql-setup.sql` script is adapted to configure NL2SQL for the `pagila` database.

## Next Steps

### 1. Deploy the MCP Server to Cloud Run
-   **Create `tools.yaml`:** Define the connection to the `pagila` database in a `tools.yaml` file. This will be done within Terraform using a `local_file` resource.
-   **Create Service Account:** Create a dedicated service account for the Cloud Run service with the necessary permissions for Secret Manager and AlloyDB.
-   **Store `tools.yaml` as a Secret:** Upload the `tools.yaml` file to Secret Manager.
-   **Deploy to Cloud Run:** Deploy the pre-built MCP Server container image to Cloud Run, configured to:
    -   Connect to the VPC network.
    -   Mount the `tools.yaml` file from Secret Manager.
    -   Securely access the database credentials.

### 2. Build the Demo Client Application
-   **Choose a Framework:** Decide on a framework for the client application (e.g., Python with Streamlit, or a simple web app with Javascript).
-   **Connect to MCP Server:** Use the Toolbox Client SDK to connect to the deployed Cloud Run service.
-   **Implement the UI:** Create a simple user interface where the user can type natural language questions.
-   **Display the Results:** Display the results returned from the MCP Server in a user-friendly format.

### 3. Create Compelling Demo Scenarios
-   **Define Business Questions:** Craft a set of interesting business questions that can be answered by querying the `pagila` database using natural language.
-   **Prepare Demo Script:** Write a script for the demo, highlighting the key features and benefits of the solution.
