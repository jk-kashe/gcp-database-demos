import os
import google.auth.transport.requests
import google.oauth2.id_token
from google.adk.agents import LlmAgent
from google.adk.planners.built_in_planner import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams
from google.genai.types import ThinkingConfig

# Get the MCP Server URL from the environment variable set in Terraform.
MCP_SERVER_URL = os.environ.get("MCP_TOOLBOX_URL")
if not MCP_SERVER_URL:
    raise ValueError("The MCP_TOOLBOX_URL environment variable is not set.")

def get_id_token():
    """Get an ID token to authenticate with the MCP server."""
    # The audience is the root URL of the Cloud Run service.
    audience = MCP_SERVER_URL.split('/mcp')[0] if '/mcp' in MCP_SERVER_URL else MCP_SERVER_URL
    auth_req = google.auth.transport.requests.Request()
    id_token = google.oauth2.id_token.fetch_id_token(auth_req, audience)
    return id_token

# The ADK runtime will look for an agent instance to run.
agent = LlmAgent(
    model=os.environ.get("ADK_AGENT_MODEL", 'gemini-2.5-flash'),
    name=os.environ.get("ADK_AGENT_NAME", 'mcp_agent'),
    description=os.environ.get("ADK_AGENT_DESCRIPTION", 'Agent to interact with an MCP server.'),
    instruction=(os.environ.get("ADK_AGENT_INSTRUCTION",
        'You are a helpful agent who can answer user questions by using the tools available from the MCP server.'
    )),
    planner=BuiltInPlanner(
        thinking_config=ThinkingConfig(
            include_thoughts=os.environ.get("ADK_AGENT_INCLUDE_THOUGHTS", "False").lower() == "true",
            thinking_budget=int(os.environ.get("ADK_AGENT_THINKING_BUDGET", 0))
        )
    ),
    tools=[
        MCPToolset(
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