# ☕ Oracle + Vertex AI Coffee Demo

An intelligent coffee recommendation system showcasing Oracle 23AI vector search with Google Vertex AI integration.

This fork of the original version is intended to work with Oracle Autonomous@GCP. See https://github.com/jk-kashe/oracledb-vertexai-demo for details

## 🚀 Quick Start

1. Create a new Google Cloud project.
2. Subscribe to Oracle Database@Google Cloud and complete account linking.
3. Open Cloud Shell and run the following commands:
```
git clone https://github.com/jk-kashe/gcp-database-demos
cd gcp-database-demos/oracle_on_gcp/coffee
make apply
```
4. The configuration script will prompt you to provide:
- GCP Project ID
- GCP region
5. Once deployed, navigate to Cloud Run and click the url to start the application
6. To un-deploy, run 
```
make destory 
```
