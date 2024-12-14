#!/bin/bash
# execute_ddl.sh

# Replace newlines with spaces
file_content=$(sed ':a;N;$!ba;s/\n/ /g' < files/search_indexes.sql)
file_content="${file_content};"

# Use IFS to split the string by semicolon
IFS=';' read -r -a sql_statements <<< "$file_content"

# Now you can iterate through the array and process each SQL statement
for statement in "${sql_statements[@]}"; do
  # Trim leading/trailing whitespace from each statement without using xargs
  statement=$(echo "$statement" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [[ ! -z "$statement" ]]; then
    echo "Processing statement: $statement;"
    gcloud spanner databases ddl update "$1" \
    --project="$2" \
    --instance="$3" \
    --ddl="$statement"
  fi
done