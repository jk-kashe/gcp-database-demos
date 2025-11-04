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

    print(f"--- Loading agent from 'src.agent' ---", file=sys.stderr)
    try:
        # Import the agent using the full package path.
        # This is now possible because of the __init__.py file.
        from src.agent import root_agent
    except Exception as e:
        import traceback
        print("--- !!! ENCOUNTERED AN EXCEPTION WHILE IMPORTING AGENT !!! ---", file=sys.stderr)
        print(f"ERROR TYPE: {type(e).__name__}", file=sys.stderr)
        print(f"ERROR DETAILS: {e}", file=sys.stderr)
        print("--- STACK TRACE ---", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        print("--- END STACK TRACE ---", file=sys.stderr)
        sys.exit(1)


    print(f"--- Wrapping agent '{root_agent.name}' in AdkApp ---", file=sys.stderr)
    app = agent_engines.AdkApp(
        agent=root_agent,
        enable_tracing=True,
    )

    requirements_path = os.path.join(agent_app_path, "requirements.txt")
    print(f"--- Loading requirements from: {requirements_path} ---", file=sys.stderr)
    try:
        with open(requirements_path, "r") as f:
            requirements = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Warning: requirements.txt not found at {requirements_path}. Deploying without explicit requirements.", file=sys.stderr)
        requirements = []

    print(f"--- Deploying to Agent Engine with display name: '{display_name}' and requirements: {requirements} ---", file=sys.stderr)
    remote_agent = agent_engines.create(
        app,
        display_name=display_name,
        requirements=requirements,
        extra_packages=[agent_app_path],
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
