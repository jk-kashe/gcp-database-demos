from adk.agent import Agent
from adk.llm import LlmAgent
from adk.tool import MCPToolset
import os


class MCPAgent(LlmAgent):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.add_toolset(MCPToolset(url=os.environ["MCP_TOOLBOX_URL"]))


if __name__ == "__main__":
    agent = Agent(MCPAgent)
    agent.start()
