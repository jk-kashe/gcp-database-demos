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

## Connecting to APEX

To access the APEX web interface, you'll need to forward a local port to the port on the VM where APEX is running (port 8181).

1.  **Find your VM's zone:**
    You can find the zone of your `oracle-vm` instance in the GCP console or by running the following command:
    ```bash
    gcloud compute instances describe oracle-vm --format='get(zone)'
    ```

2.  **Set up port forwarding:**
    Use the following `gcloud` command to set up port forwarding. This command will forward your local port 8181 to the VM's port 8181.
    ```bash
    gcloud compute ssh oracle-vm --zone <your-vm-zone> -- -L 8181:localhost:8181
    ```
    Keep this terminal window open.

3.  **Access APEX in your browser:**
    Open a web browser and navigate to:
    [http://localhost:8181/ords/apex](http://localhost:8181/ords/apex)