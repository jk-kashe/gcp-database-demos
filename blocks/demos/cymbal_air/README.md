# AlloyDB AI & Vector Search Demo

This repository provides a demonstration of a GenAI Vector Search application powered by AlloyDB. It showcases AlloyDB's capabilities in AI-powered applications, particularly in the domain of retrieval augmented generation (RAG).

## Purpose

This demo aims to provide an easy-to-deploy and impressive GenAI Vector Search application that allows you to:

* **Generate embeddings in AlloyDB** through seamless integration with Vertex AI.
* **Explore AlloyDB optimizations for Vector Search** using the ScaNN library.
* **Generate text directly in AlloyDB** by leveraging the power of Vertex AI.

This demonstration builds upon the **[GenAI Databases Retrieval App](https://github.com/GoogleCloudPlatform/genai-databases-retrieval-app/tree/main)** and highlights the practical application of techniques like RAG and ReACT in real-world scenarios.

**Note:** This project is for demonstration purposes only and is not an officially supported Google product.


## Getting Started

1. **Prerequisites:**
    * GCP Environment with sufficiently broad permissions to create various resources

2. **Deployment:**
    * Create a project to host your deployment. We recommend an empty project to avoid any unforseen issues.
    * Open Cloud Shell and set your target project as the current project
    * Run these commands:
    ```
    git clone https://github.com/jk-kashe/gcp-database-demos
    cd gcp-database-demos/alloydb/cymbal-air
    ./set-vars.sh
    ```
    * Set vars will ask you to provide variable values. Most variables should be auto-populated, but check they are correct. It's assumed you have the knowledge of GCP to find the correct values!
      * Set AlloyDB password to a reasonably secure one
      * demo_app_support_email MUST be email of the useraccount you are logged-in with in the GCP console
    * Provision the environment
    ```
    terraform init
    terraform apply
    ```


## License

This project is licensed under the [Apache License 2.0] 

## Disclaimer

This project is intended for demonstration purposes only. It is not an officially supported Google product and should not be used in production environments without careful consideration and appropriate modifications.