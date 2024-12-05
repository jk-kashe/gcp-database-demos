# AlloyDB Demos

## Prerequisites

* **Google Cloud Platform (GCP) account**
*  **Cloud Shell:** Default & preferred environment to deploy the demo

or

* **(Linux) shell environment:** Bash or similar
* **gcloud CLI:** Installed, configured, and authenticated
* **Terraform client:** Installed


## Getting Started

1. **Clone this repository.**
2. **Navigate to the `alloydb` directory.**

## Available Demos

### alloydb-ai-free-trial

This demo creates a foundational AlloyDB environment:

* Separate project
* Network
* AlloyDB trial cluster with AlloyDB AI enabled
* AlloyDB primary instance
* AlloyDB client VM

This provides a quick way to set up AlloyDB but doesn't include additional features.

### cymbal-air

This demo builds upon `alloydb-base` and deploys the demo from  [this repository](https://github.com/GoogleCloudPlatform/genai-databases-retrieval-app) . It will:

* Deploy the database schema
* Configure, build, and deploy the middleware in Cloud Run
* Configure the frontend app
* see [README.md](https://github.com/jk-kashe/gcp-database-demos/blob/main/blocks/demos/cymbal_air/README.md) and [README_VECTOR_SEARCH.md](./cymbal-air/README_VECTOR_SEARCH.md) for details.


# Disclaimer

This repository and the scripts contained within are provided as-is. Neither Google nor the authors are responsible for any costs or damages incurred through the use of these scripts. Users are responsible for understanding the potential impact of running these scripts on their Google Cloud Platform projects and associated billing!
