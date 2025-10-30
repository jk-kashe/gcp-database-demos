import vertexai
from vertexai import agent_engines
import argparse
import sys
import asyncio
from google.adk.sessions import VertexAiSessionService

# --- Configuration (Hardcoded by Terraform) ---
PROJECT_ID = "${project_id}"
LOCATION = "${location}"
REASONING_ENGINE_ID = "${reasoning_engine_id}"
USER_ID = "test-user"

def query_agent(prompt):
    """Initializes Vertex AI and sends a prompt to the specified agent."""
    
    print(f"--- Initializing Vertex AI for project '{PROJECT_ID}' in '{LOCATION}' ---", file=sys.stderr)
    vertexai.init(project=PROJECT_ID, location=LOCATION)

    print(f"--- Creating session for user: {USER_ID} ---", file=sys.stderr)
    session_service = VertexAiSessionService(PROJECT_ID, LOCATION)
    session = asyncio.run(session_service.create_session(
        app_name=REASONING_ENGINE_ID,
        user_id=USER_ID
    ))
    print(f"--- Session created: {session.id} ---", file=sys.stderr)

    print(f"--- Getting a reference to agent: {REASONING_ENGINE_ID} ---", file=sys.stderr)
    remote_agent = agent_engines.get(REASONING_ENGINE_ID)

    print(f"\n--- Querying Agent with prompt: '{prompt}' ---", file=sys.stderr)
    response_stream = remote_agent.stream_query(
        message=prompt, 
        user_id=USER_ID,
        session_id=session.id
    )

    print("\n--- Agent Response ---")
    # The main response is printed to stdout for easy capture
    for chunk in response_stream:
        print(chunk)
    print("\n--- End of Response ---", file=sys.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Query a deployed Vertex AI Agent Engine.",
        epilog="Example: ./invoke.sh \"show me all tables for the MCP_DEMO_USER schema\""
    )
    parser.add_argument(
        "prompt",
        type=str,
        help="The natural language prompt to send to the agent."
    )

    args = parser.parse_args()
    query_agent(args.prompt)
