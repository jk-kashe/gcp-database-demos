# Oracle APEX Demo

An Oracle APEX application.



## 🚀 Quick Start

1. Create a new Google Cloud project.
2. Subscribe to Oracle Database@Google Cloud and complete account linking.
3. Open Cloud Shell and run the following commands:
```
git clone https://github.com/jk-kashe/gcp-database-demos
cd gcp-database-demos/oracle_on_gcp/apex
make apply
```
4. The configuration script will prompt you to provide:
- GCP Project ID
- GCP region

5. To un-deploy, run 
```
make destory 
```

Due to network reservations, the initial network decommissioning attempt is likely to fail. Please wait a few hours and run the destroy command again.

## Accessing APEX

The APEX application is deployed on Cloud Run. After running `make apply`, the public URL for the application will be displayed as a Terraform output named `apex_url`.

You can also retrieve the URL at any time by running the following command in the `tf` directory:
```bash
terraform output apex_url
```
