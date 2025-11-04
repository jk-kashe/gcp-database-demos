from google.adk.agents import LlmAgent, ReadonlyContext
from google.adk.planners.built_in_planner import BuiltInPlanner
from google.adk.tools.mcp_tool.mcp_toolset import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams
from google.genai.types import ThinkingConfig
from auth import get_id_token

# This will be replaced by Terraform. Strip any hidden whitespace/newlines.
_mcp_server_url_base = "${mcp_toolbox_url}".strip()
MCP_SERVER_URL = _mcp_server_url_base if _mcp_server_url_base.endswith('/mcp') else _mcp_server_url_base + '/mcp'
AUDIENCE = MCP_SERVER_URL.removesuffix('/mcp')

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
            ),
            header_provider=lambda ctx: {"Authorization": f"Bearer {get_id_token(AUDIENCE)}"},
            errlog=None,
            tool_filter=None,
        )
    ],
)

