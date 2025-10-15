#!/bin/bash

mkdir -p ./.gemini
TOKEN=$(gcloud auth print-identity-token --audiences='${mcp_server_url}')

cat <<EOF > ./.gemini/settings.json
{
  "mcpServers": {
    "pagila-mcp": {
      "httpUrl": "${mcp_server_url}/mcp",
    "headers": {
        "Authorization": "Bearer $TOKEN" 
    }
  }
}
}
EOF
