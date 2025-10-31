import os
import sys
import google.auth
import google.auth.transport.requests
import google.oauth2.id_token
from google.adk.agents import LlmAgent
from google.adk.planners.built_in_planner import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams
from google.genai.types import ThinkingConfig

# This will be replaced by Terraform. Strip any hidden whitespace/newlines.
_mcp_server_url_base = "${mcp_toolbox_url}".strip()
MCP_SERVER_URL = _mcp_server_url_base if _mcp_server_url_base.endswith('/mcp') else _mcp_server_url_base + '/mcp'

def get_id_token():
    """Get an ID token to authenticate with the MCP server."""
    try:
        creds, project = google.auth.default()
        if hasattr(creds, 'service_account_email'):
            print(f"Running as service account: {creds.service_account_email}", file=sys.stderr)
        else:
            print("Could not determine service account email from credentials.", file=sys.stderr)
    except Exception as e:
        print(f"Error getting default credentials: {e}", file=sys.stderr)

    print(f"MCP_SERVER_URL for toolset: {MCP_SERVER_URL}", file=sys.stderr)
    # The audience is the root URL of the Cloud Run service, without the /mcp path.
    audience = MCP_SERVER_URL.removesuffix('/mcp')
    print(f"Audience for ID token: {audience}", file=sys.stderr)
    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, audience)
    print(f"ID token fetched (first 10 chars): {id_token[:10]}...", file=sys.stderr)
    return id_token

# The ADK runtime will look for an agent instance to run.
root_agent = LlmAgent(
    model="${adk_agent_model}",
    name="${adk_agent_name}",
    description="${adk_agent_description}",
    instruction='''${adk_agent_instruction}''',
    planner=BuiltInPlanner(
        thinking_config=ThinkingConfig(
            include_thoughts=${adk_agent_include_thoughts},
            thinking_budget=${adk_agent_thinking_budget}
        )
    ),
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=MCP_SERVER_URL,
                headers={
                    "Authorization": f"Bearer {get_id_token()}",
                },
            ),
            errlog=sys.stderr,
            # Load all tools from the MCP server at the given URL
            tool_filter=None,
        )
    ],
)
