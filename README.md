# GCP Databases Demos

Note: This project is for demonstration only and is not an officially supported Google product.

## Introduction

This repository is (going to be) a collection of ready-to-deploy demo projects for various Google Cloud databases. Explore the power and flexibility of Google Cloud's database offerings with easy-to-follow instructions and examples.


## Features

* **Easy Deployment:** Get started quickly with simple, canned deployment scripts.
* **Wide Range of Databases:** We are starting with AlloyDB, but going forward we want to expand to a wide range of GCP Databases

## Available Demos (By Subfolder)

| Database     | Description                                           | Status |
|---------------|-------------------------------------------------------|--------|
| [AlloyDB](./alloydb/README.md)	   | PostgreSQL-compatible managed database for enterprise workloads | ✅     |
| Spanner      | Distributed SQL for mission-critical applications     | 🚧     |
| Firestore    | NoSQL document database for mobile and web apps        | 🚧     |
| Cloud SQL    | Fully managed relational database for MySQL, PostgreSQL, SQL Server | 🚧     |
| Bigtable      | Wide-column NoSQL for large-scale, low-latency workloads | 🚧     |
| Memorystore   | In-memory data store for Redis and Memcached            | 🚧     |

## How to Use

1. **Navigate to a Database Subfolder:** Choose the database you want to explore.
2. **Read the README.md:** Find detailed instructions and demo descriptions.
3. **Deploy and Experiment:** Follow the provided steps to get hands-on experience.

## Notes

* This repository does not host the demos themselves, only packages them for easier deployment.
See license of referenced repositories for licensing information.

* These scripts are not in any way supported by Google.

* These scripts are not meant to be run on a production environment or even be considered as
a source of best practices - on the contrary, as the objective is only to provide canned demos,
they are likely to contain bugs and anty-patterns.

# Disclaimer

This repository and the scripts contained within are provided as-is. Neither Google nor the authors are responsible for any costs or damages incurred through the use of these scripts. Users are responsible for understanding the potential impact of running these scripts on their Google Cloud Platform projects and associated billing!
