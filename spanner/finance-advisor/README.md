# Finvest Spanner Demo App

This demo deploys [Finvest Spanner Demo App](https://github.com/GoogleCloudPlatform/generative-ai/tree/main/gemini/sample-apps/finance-advisor-spanner).

Please see the original repository [README](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/sample-apps/finance-advisor-spanner/README.md) for details.

Contributors: [J.K. Kashe](https://github.com/jk-kashe) & [Tom Botril](https://github.com/tombotch)

## Deploying the demo

### IMPORTANT

**This demo will incure charges on your project**, as it is using spanner enterprise. 

### Prereqs

- Have a fresh, empty project ready
- Sufficient permissions to enable APIs, grant roles, provision resources, ...
- Policies must permit public cloud run services 

### Deployment
In the GCP Cloud Shell (we have not tested deployment in non-shell environments)

```
git clone https://github.com/jk-kashe/gcp-database-demos
cd gcp-database-demos/spanner/finance-advisor
./set-vars.sh
terraform init
terraform apply
```

### Notes

- The script takes a long time to execute > 1h
- GCP shell might time out if it receives no input - please periodically hit enter key to prevent it
- Some DDL commands might time out through gcloud - monitor output and re-run them through the spanner studio if needed

### Starting the Demo

After provisioning, navigate to Cloud Run, where you will find the application service. Click on the service and open the service url.