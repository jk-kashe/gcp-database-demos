import os
import google.auth.transport.requests
import google.oauth2.id_token
from google.adk.agents import LlmAgent
from google.adk.planners.built_in_planner import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams
from google.genai.types import ThinkingConfig

# This will be replaced by Terraform
MCP_SERVER_URL = "${mcp_toolbox_url}"

def get_id_token():
    """Get an ID token to authenticate with the MCP server."""
    # The audience is the root URL of the Cloud Run service.
    audience = MCP_SERVER_URL.split('/mcp')[0] if '/mcp' in MCP_SERVER_URL else MCP_SERVER_URL
    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, audience)
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
                }
            ),
            errlog=None,
            # Load all tools from the MCP server at the given URL
            tool_filter=None,
        )
    ],
)
