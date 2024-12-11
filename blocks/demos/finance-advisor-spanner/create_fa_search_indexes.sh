#!/bin/bash
# execute_ddl.sh

# Replace newlines with spaces
file_content=$(sed ':a;N;$!ba;s/\n/ /g' < search_indexes.sql)
file_content="${file_content};"

# Use IFS to split the string by semicolon
IFS=';' read -r -a sql_statements <<< "$file_content"

# Trim leading/trailing whitespace from each statement
for ((i=0; i<${#sql_statements[@]}; i++)); do
  sql_statements[$i]=$(echo "${sql_statements[$i]}" | xargs)
done

# Now you can iterate through the array and process each SQL statement
for statement in "${sql_statements[@]}"; do
  if [[ ! -z "$statement" ]]; then
    echo "Processing statement: $statement;"
    gcloud spanner databases ddl update "$1" \
    --project="$2" \
    --instance="$3" \
    --ddl="$statement"
  fi
done