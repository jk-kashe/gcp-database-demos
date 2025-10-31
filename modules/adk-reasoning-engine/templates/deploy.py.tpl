import vertexai
from vertexai import agent_engines
import argparse
import sys
import os
from importlib.util import spec_from_file_location, module_from_spec

def deploy_agent(project_id, location, staging_bucket, display_name, agent_app_path, output_file_path):
    """Deploys the ADK agent."""
    print(f"--- Initializing Vertex AI for project '{project_id}' in '{location}' ---", file=sys.stderr)
    vertexai.init(project=project_id, location=location, staging_bucket=staging_bucket)

    # The agent is expected to be in agent.py as `root_agent` in the current directory
    agent_file_path = os.path.join(agent_app_path, "agent.py")
    print(f"--- Loading agent from: {agent_file_path} ---", file=sys.stderr)
    try:
        spec = spec_from_file_location("agent", agent_file_path)
        agent_module = module_from_spec(spec)
        sys.modules["agent"] = agent_module
        spec.loader.exec_module(agent_module)
        root_agent = agent_module.root_agent
    except Exception as e:
        print(f"Error loading agent: {e}", file=sys.stderr)
        sys.exit(1)


    print(f"--- Wrapping agent '{root_agent.name}' in AdkApp ---", file=sys.stderr)
    app = agent_engines.AdkApp(
        agent=root_agent,
        enable_tracing=True,
    )

    print(f"--- Deploying to Agent Engine with display name: '{display_name}' ---", file=sys.stderr)
    # The requirements are automatically picked up from the active virtual environment.
    remote_agent = agent_engines.create(
        app,
        display_name=display_name
    )

    print(f"--- Agent Engine created. Resource name: {remote_agent.resource_name} ---", file=sys.stderr)

    # Write the resource name to the output file.
    with open(output_file_path, "w") as f:
        f.write(remote_agent.resource_name)
    print(f">>> Deployment complete. Output written to {output_file_path}", file=sys.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy an ADK agent to Vertex AI Agent Engine.")
    parser.add_argument("--project", required=True, help="Google Cloud project ID.")
    parser.add_argument("--region", required=True, help="Google Cloud region.")
    parser.add_argument("--staging_bucket", required=True, help="GCS bucket for staging.")
    parser.add_argument("--display_name", required=True, help="Display name for the agent.")
    parser.add_argument("--agent_app_path", default=".", help="Path to the agent application source code.")
    parser.add_argument("--output_file", required=True, help="File to write the deployed agent's resource name to.")

    args = parser.parse_args()
    deploy_agent(
        project_id=args.project,
        location=args.region,
        staging_bucket=args.staging_bucket,
        display_name=args.display_name,
        agent_app_path=args.agent_app_path,
        output_file_path=args.output_file
    )
