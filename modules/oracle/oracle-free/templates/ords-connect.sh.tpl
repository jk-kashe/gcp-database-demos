#!/bin/bash
echo "Starting port forwarding. Press Ctrl+C to exit."
echo "  - VM Port 8080 (ORDS) is forwarded to localhost:8080"
echo "  - VM Port 1521 (DB)   is forwarded to localhost:1521"
gcloud compute ssh ${vm_name} --zone=${zone} --project=${project_id} --tunnel-through-iap -- -L 8080:localhost:8080 -L 1521:localhost:1521 -N
