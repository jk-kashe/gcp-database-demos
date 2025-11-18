# Oracle APEX on Google Cloud with Gemini AI

This project deploys a powerful demonstration environment showcasing Oracle APEX running on an Oracle Free Database on Google Cloud, supercharged with Google's AI ecosystem. It seamlessly integrates the Google Cloud MCP Toolbox to connect your Oracle database with advanced AI agents like Gemini CLI and Gemini Enterprise, unlocking natural language querying and AI-driven insights from your data.

---

## 📜 Licensing and Disclaimer

### Oracle Software Licensing

**Important:** This project automates the deployment of software provided by Oracle, including **Oracle Free Database**, **Oracle REST Data Services (ORDS)**, and **Oracle APEX**. By using this deployment, you are responsible for accepting and adhering to the applicable Oracle licensing terms. This repository _does not_ contain or distribute any Oracle software itself; it only automates the download and configuration process from official Oracle sources.

### Disclaimer

This Terraform configuration is for **demonstration purposes only**. It is not designed for production use and may not adhere to security, scalability, or operational best practices for a production environment.

---

## 🚀 Quick Start

### Prerequisites

1.  A Google Cloud project with billing enabled.
2.  The `gcloud` CLI installed and authenticated.

### Deployment Steps

1.  Open Google Cloud Shell or your local terminal.
2.  Clone the repository:
    ```bash
    git clone https://github.com/jk-kashe/gcp-database-demos
    cd gcp-database-demos/oracle_on_gcp/oracle-and-gemini-ai
    ```
3.  Start the deployment:
    ```bash
    make apply
    ```
4.  The script will prompt you to provide required configuration parameters, such as your GCP Project ID and region.

### Post-Deployment Setup

Once the `make apply` command completes, follow these steps to set up the APEX application and connect to your AI agents.

#### 1. Configure APEX Application

1.  The script will output a URL for the ORDS deployment (`apex_url`). Open this URL in your browser.
2.  Select **APEX**.
3.  Log in to the workspace:
    *   **Workspace:** `DEMO`
    *   **User:** `DEMO`
    *   **Password:** The same password you provided for the Oracle database `sys` user during setup.
4.  In the APEX dashboard, navigate to the **App Gallery**, find the **Starter Apps**, and install the **Opportunities** application.
5.  After installation, click **Run Application** to complete the setup.

    > **Known Issue:** When you run the app, the URL may incorrectly include port `:80`. If the page doesn't load, simply **remove `:80`** from the URL in your browser's address bar and press Enter. You will be prompted to log in again with the `DEMO` user and password.

#### 2. Connect with Gemini CLI in Cloud Shell

1.  Navigate back to the `oracle_on_gcp/oracle-and-gemini-ai` directory in your Cloud Shell terminal.
2.  Run the settings script to configure the MCP Toolbox connection:
    ```bash
    ./update_settings.sh
    ```
3.  Launch the Gemini CLI:
    ```bash
    gemini
    ```
4.  Instruct Gemini to load the database schema. This allows it to understand your data structure.
    ```prompt
    load all objects for WKSP_DEMO schema and stand by. Do not echo results
    ```
5.  Allow the tool to execute the three MCP calls to list tables, columns, and foreign keys.
6.  Now, you can ask questions in natural language!
    ```prompt
    what are our top 3 opportunities
    ```

#### 3. Connect with Gemini Enterprise

1.  In the Google Cloud Console, navigate to the **Gemini** service.
2.  Find and open the app named **"Gemini ❤️ Oracle"** and click **Preview**.
3.  In the chat interface, start your prompt with the `@` symbol. A list of available tools will appear.
4.  Select the **"Oracle NL2SQL Agent"**.
5.  Ask your question, specifying the table name:
    ```prompt
    @Oracle NL2SQL Agent What are our top 10 opportunities in EBA_SALES_OPPORTUNITIES_V
    ```
    Here are some more examples of business-oriented questions you can ask:
    *   **Performance Analysis:** `@Oracle NL2SQL Agent Which sales representative has the highest total deal amount this quarter?`
    *   **Forecasting:** `@Oracle NL2SQL Agent What is our total weighted forecast for all open opportunities closing next quarter?`
    *   **Customer Insights:** `@Oracle NL2SQL Agent Which customer has the most open opportunities by value?`
    *   **Pipeline Health:** `@Oracle NL2SQL Agent List all open deals with a probability equal or higher than 50% that are scheduled to close this year.`

---

## 🏗️ Architecture Overview

This project provisions the following resources in your Google Cloud project:

*   **Oracle Free Database:** Deployed in a Docker container on a single Compute Engine VM for simplicity and isolation.
*   **ORDS & APEX:** The Oracle REST Data Services and APEX applications are installed alongside the database on the VM.
*   **Cloud Run for ORDS:** A serverless, scalable Cloud Run service is deployed to expose the ORDS/APEX frontend to the web securely.
*   **Google Cloud MCP Toolbox:** A service that acts as a bridge, enabling secure and authenticated connections between Google's AI services and the private Oracle database.
*   **ADK Reasoning Engine:** An agent built using the Agent Development Kit (ADK) that defines the tools and logic required to translate natural language into Oracle SQL queries via the MCP Toolbox.
*   **Gemini Enterprise App:** A dedicated search and conversational AI application that is connected to your Oracle database through the ADK agent, enabling the powerful natural language query capabilities.
