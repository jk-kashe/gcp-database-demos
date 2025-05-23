# AlloyDB Demos

## Prerequisites

* **Google Cloud Platform (GCP) account**
*  **Cloud Shell:** Default & preferred environment to deploy the demo

or

* **(Linux) shell environment:** Bash or similar
* **gcloud CLI:** Installed, configured, and authenticated
* **Terraform client:** Installed


## Getting Started


1. Login to the [Google Cloud Console](https://console.cloud.google.com/).

2. [Create a new project](https://developers.google.com/maps/documentation/places/web-service/cloud-setup) to host the demo and isolate it from other resources in your account.

3. [Switch](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects) to your new project.

4. [Activate Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell) and confirm your project by running the follow4ng commands. Click **Authorize** if prompted.

   ```bash
   gcloud auth list
   gcloud config list project
   ```
5. **Clone this repository.**
   It's a good idea to clone the repository in a folder of the same name as your project, to keep track what belongs where
6. **Navigate to the directory of the demo you would like to deploy.**
7. **Follow the README** in the demo directory
   

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

This demo builds upon `alloydb-ai-free-trial` and deploys the demo from  [this repository](https://github.com/GoogleCloudPlatform/genai-databases-retrieval-app) . It will:

* Deploy the database schema
* Configure, build, and deploy the middleware in Cloud Run
* Configure the frontend app
* see [README.md](https://github.com/jk-kashe/gcp-database-demos/blob/main/blocks/demos/cymbal_air/README.md) and [README_VECTOR_SEARCH.md](./cymbal-air/README_VECTOR_SEARCH.md) for details.

### agentspace

This demo builds upon `alloydb-ai-free-trial` and deploys the demo from  [this repository](https://github.com/GoogleCloudPlatform/genai-databases-retrieval-app) . It will:

* Deploy the database schema
* Configure, build, and deploy the middleware in Cloud Run

# Disclaimer

This repository and the scripts contained within are provided as-is. Neither Google nor the authors are responsible for any costs or damages incurred through the use of these scripts. Users are responsible for understanding the potential impact of running these scripts on their Google Cloud Platform projects and associated billing!
