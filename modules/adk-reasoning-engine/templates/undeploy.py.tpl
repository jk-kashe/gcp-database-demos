import vertexai
import argparse
import sys
from google.api_core import exceptions

def undeploy_agent(resource_name):
    """Deletes the ADK agent using the vertexai.Client."""
    if not resource_name or not resource_name.strip():
        print("Reasoning engine resource name is empty. Skipping deletion.", file=sys.stderr)
        return

    try:
        # Extract project and location from the resource name (e.g., projects/proj/locations/loc/...)
        parts = resource_name.split('/')
        if len(parts) < 4 or parts[0] != 'projects' or parts[2] != 'locations':
             raise ValueError(f"Invalid resource name format: {resource_name}")
        project_id = parts[1]
        location = parts[3]

        print(f"--- Initializing Vertex AI Client for project '{project_id}' in '{location}' ---", file=sys.stderr)
        client = vertexai.Client(project=project_id, location=location)

        print(f"--- Deleting agent: {resource_name} ---", file=sys.stderr)
        client.agent_engines.delete(name=resource_name, force=True)
        print(f"--- Deletion command issued for {resource_name} ---", file=sys.stderr)

    except exceptions.NotFound:
        print(f"Agent {resource_name} not found. It might have been already deleted.", file=sys.stderr)
    except ValueError as e:
        print(f"Error parsing resource name: {e}", file=sys.stderr)
    except Exception as e:
        print(f"An unexpected error occurred during deletion: {e}", file=sys.stderr)
        # Do not exit with an error to allow other 'destroy' operations to continue.

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete a deployed Vertex AI Agent Engine.")
    parser.add_argument(
        "--resource_name",
        required=True,
        type=str,
        help="The full resource name of the agent to delete."
    )

    args = parser.parse_args()
    undeploy_agent(args.resource_name)