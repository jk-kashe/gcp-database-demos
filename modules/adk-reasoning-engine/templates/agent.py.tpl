import os
import sys
import time
from typing import Dict
import google.auth
import google.auth.transport.requests
import google.oauth2.id_token
from google.adk.agents import LlmAgent
from google.adk.planners.built_in_planner import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams
from google.adk.runtime.context import ReadonlyContext
from google.genai.types import ThinkingConfig

# --- Token Caching ---
_cached_token = None
_token_expiry_time = 0
# Refresh token 5 minutes before it expires (tokens last 1 hour)
_token_refresh_buffer_seconds = 300

# This will be replaced by Terraform. Strip any hidden whitespace/newlines.
_mcp_server_url_base = "${mcp_toolbox_url}".strip()
MCP_SERVER_URL = _mcp_server_url_base if _mcp_server_url_base.endswith('/mcp') else _mcp_server_url_base + '/mcp'

def get_id_token():
    """
    Get a cached ID token, refreshing it if it's close to expiring.
    """
    global _cached_token, _token_expiry_time

    current_time = time.time()

    # If the token is missing or is about to expire, fetch a new one.
    if not _cached_token or current_time > _token_expiry_time - _token_refresh_buffer_seconds:
        print("Fetching new ID token...", file=sys.stderr)
        try:
            creds, project = google.auth.default()
            if hasattr(creds, 'service_account_email'):
                print(f"Running as service account: {creds.service_account_email}", file=sys.stderr)
        except Exception as e:
            print(f"Error getting default credentials: {e}", file=sys.stderr)

        audience = MCP_SERVER_URL.removesuffix('/mcp')
        auth_req = google.auth.transport.requests.Request()
        new_token = google.oauth2.id_token.fetch_id_token(auth_req, audience)
        
        _cached_token = new_token
        _token_expiry_time = current_time + 3600  # 1 hour in seconds
        print(f"ID token refreshed. New expiry in approx 1 hour.", file=sys.stderr)
    
    return _cached_token

def create_auth_headers(context: ReadonlyContext) -> Dict[str, str]:
    """
    This function is the header_provider. It's called by the McpToolset
    to get fresh authentication headers for each request.
    """
    token = get_id_token()
    return {"Authorization": f"Bearer {token}"}

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
                # The headers are now supplied by the provider function below.
            ),
            header_provider=create_auth_headers,
            errlog=None,
            tool_filter=None,
        )
    ],
)