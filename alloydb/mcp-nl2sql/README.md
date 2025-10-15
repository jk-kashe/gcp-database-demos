# AlloyDB AI: Natural Language to SQL (NL2SQL) and Model-Client-Proxy (MCP) Demo

This repository provides deployment scripts for a demonstration that showcases two powerful patterns for building natural language query capabilities on a PostgreSQL database using AlloyDB and Gemini.

## Purpose

This demo aims to provide an easy-to-deploy environment to explore and contrast two architectures for Natural Language to SQL (NL2SQL):

1.  **The Intelligent Database:** Leveraging AlloyDB AI's built-in `NL2SQL` functions. This approach integrates the language model directly with the database, offering an efficient, scalable, and programmable engine for production use cases.
2.  **The Intelligent Client:** Using the Model-Client-Proxy (MCP) architecture with the `gemini-cli`. This pattern acts as a "universal translator," allowing you to add natural language capabilities to any application or database without modifying the database itself.

The demo uses the standard `pagila` sample database.

**Note:** This deployment script is for demonstration purposes only and is not an officially supported Google product.

## Architecture

The `make apply` command deploys the following components:

*   **AlloyDB for PostgreSQL Cluster:** A new cluster with the AlloyDB AI extension enabled.
*   **Pagila Database:** The AlloyDB cluster is populated with the `pagila` schema and data.
*   **Client VM:** A GCE virtual machine with `psql` and other tools pre-configured to connect to the AlloyDB cluster.
*   **MCP Cloud Run Service:** A lightweight, serverless proxy that exposes the Pagila database to the `gemini-cli` via a secure API. It understands how to execute SQL against the database.
*   **Service Accounts and Permissions:** All necessary IAM roles and permissions for the components to interact securely.

## Getting Started

### Prerequisites

*   A GCP Project with billing enabled.
*   The gcloud CLI installed and authenticated (`gcloud auth login`).
*   Sufficient permissions in the project to create the resources listed in the Architecture section.

### Deployment

1.  Open Cloud Shell or a local terminal where `gcloud` is configured.

2.  Clone the repository:
    ```bash
    git clone https://github.com/GoogleCloudPlatform/gcp-database-demos
    cd gcp-database-demos/alloydb/mcp-nl2sql
    ```

3.  Run the deployment script:
    ```bash
    make apply
    ```

4.  The script will prompt you to enter values for variables that do not have a default, such as your `demo_project_id`, `billing_account_id`, and a password for the `alloydb_password`. The script attempts to auto-detect sensible defaults where possible.

The deployment process will take several minutes to complete.

## How to Use the Demo

This demo is split into two parts, corresponding to the two architectural patterns.

### Part 1: The Intelligent Client (MCP and `gemini-cli`)

This path demonstrates how a powerful client tool can generate complex SQL through a proxy, without any special features enabled in the database itself.

The deployment automatically creates a `.gemini/settings.json` file in the root of this demo's directory. This file configures the `gemini-cli` to use the newly deployed MCP server.

1.  **Ask a Complex Question:**
    From the `mcp-nl2sql` directory, run the following `gemini` command. This is a complex analytical question that is difficult to express in a single SQL query.

    ```bash
    gemini 'For each store, identify the top 3 film categories that have generated the most rental revenue. Within each of those top categories, find the single actor who has appeared in the most films. Finally, for that specific actor, calculate their total rental revenue within that category and store, and express this as a percentage of the category total revenue for that store.'
    ```

2.  **Observe the Result:**
    The `gemini-cli` will communicate with the Gemini model, which in turn will use the `pagila_sql` tool exposed by the MCP server to construct and execute the necessary SQL query. You will see the final answer printed to your console.

This demonstrates the power of the MCP pattern to create expert-level tools for data analysis.

### Part 2: The Intelligent Database (AlloyDB AI)

This path demonstrates the power and efficiency of building NL2SQL capabilities directly into the database.

1.  **Connect to the Client VM:**
    Use `gcloud` to SSH into the client VM. The deployment outputs will provide the necessary command, but it will look similar to this:
    ```bash
    gcloud compute ssh alloydb-client --project <YOUR_PROJECT_ID> --zone <YOUR_ZONE> --tunnel-through-iap
    ```

2.  **Connect to the Database:**
    Once on the client VM, connect to the `pagila` database using the `psql` command. You will be prompted for the AlloyDB password you provided during setup.
    ```bash
    psql -h <ALLOYDB_IP_ADDRESS> -U postgres -d pagila
    ```

3.  **Run Simple NL Queries:**
    AlloyDB AI can handle simple natural language questions out-of-the-box. Try a few examples:
    ```sql
    SELECT alloydb_ai_nl.execute_nl_query(
      'pagila_demo_cfg',
      'Show me our top 10 most-rented action movies from last month'
    );

    SELECT alloydb_ai_nl.execute_nl_query(
      'pagila_demo_cfg',
      'How many customers do we have by city'
    );
    ```

4.  **Handling Complexity with Templates:**
    Out of the box, the efficient model used by AlloyDB AI may struggle with the highly complex "heroic" query from Part 1. However, AlloyDB AI is **programmable**. A developer can "teach" the database how to answer this *class* of questions by providing a parameterized SQL template.

    During setup, this demo automatically installed a template to handle the complex query. You can now ask the heroic question directly in SQL:

    ```sql
    SELECT alloydb_ai_nl.execute_nl_query(
      'pagila_demo_cfg',
      'For each store, identify the top 3 film categories that have generated the most rental revenue. Within each of those top categories, find the single actor who has appeared in the most films. Finally, for that specific actor, calculate their total rental revenue within that category and store, and express this as a percentage of the category total revenue for that store.'
    );
    ```
    Thanks to the template, the database now understands how to construct the correct query and returns the result efficiently.

## Cleanup

To avoid incurring future charges, destroy the created resources.

1.  From the `mcp-nl2sql` directory, run:
    ```bash
    make destroy
    ```

2.  Confirm the destruction when prompted.

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Disclaimer

This project is intended for demonstration purposes only. It is not an officially supported Google product and should not be used in production environments without careful consideration and appropriate modifications.
