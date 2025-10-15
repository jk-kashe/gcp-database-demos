#!/bin/bash

# Create the variables directory if it doesn't exist
mkdir -p /opt/oracle/variables

# Write the connection string from the environment variable to the file
echo "CONN_STRING=${CONN_STRING}" > /opt/oracle/variables/conn_string.txt

# Start the ORDS service, listening on the port specified by the PORT env var
/opt/oracle/bin/ords --config /etc/ords/config serve --port ${PORT}
