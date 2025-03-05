#!/bin/bash
# Runs a DDL update and checks operation status

# Run DDL update
OPERATION=$(gcloud spanner databases ddl update $SPANNER_DATABASE --instance $SPANNER_INSTANCE --ddl-file $DDL_FILE --async 2>&1)
OPERATION_ID=$(echo $OPERATION | sed 's/Schema update in progress. Operation name=//')
DONE=""
ERROR=""

# Check operation status
while [[ -z $DONE ]]; do
    OPERATION_STATUS=$(gcloud spanner operations describe $OPERATION_ID --instance $SPANNER_INSTANCE --database $SPANNER_DATABASE)
    DONE=$(echo $OPERATION_STATUS | sed -n "/done:/p")
    ERROR=$(echo $OPERATION_STATUS | sed -n "/error:/p")

    if [[ -z $DONE ]]; then
        echo "Operation in progress...sleeping for 30 seconds..."
        sleep 30
    fi
done

if [[ -z ERROR ]]; then
    echo "Operation completed successfully"
    exit 0
else
    echo "Operation failed"
    exit 1
fi