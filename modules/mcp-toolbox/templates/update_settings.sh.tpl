#!/bin/bash
set -e

CONFIG_PATH="${config_path}"

echo "Generating Gemini CLI config at $CONFIG_PATH..."
TOKEN=$(gcloud auth print-identity-token --audiences='${mcp_server_url}')

cat <<EOF > "$CONFIG_PATH"
{
  "mcpServers": {
    "${mcp_server_name}": {
      "httpUrl": "${mcp_server_url}/mcp",
      "headers": {
        "Authorization": "Bearer $TOKEN"
      }
    }
  }
}
EOF
echo "Done."