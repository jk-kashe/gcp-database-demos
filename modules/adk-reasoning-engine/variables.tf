variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The region to provision resources in."
  type        = string
}

variable "mcp_toolbox_url" {
  description = "The URL of the MCP toolbox to be injected into the Python agent code."
  type        = string
}

variable "agent_display_name" {
  description = "The name for the agent in Agentspace (e.g., 'Oracle NL2SQL Agent')."
  type        = string
}

variable "agent_app_name" {
  description = "A short, code-friendly name for the ADK app."
  type        = string
}

variable "staging_bucket_name" {
  description = "The GCS bucket required by the ADK tool for deployment artifacts."
  type        = string
}

variable "adk_agent_model" {
  description = "The model to use for the ADK agent."
  type        = string
  default     = "gemini-2.5-flash"
}

variable "adk_agent_name" {
  description = "The name of the ADK agent."
  type        = string
  default     = "mcp_agent"
}

variable "adk_agent_description" {
  description = "The description of the ADK agent."
  type        = string
  default     = "Agent to interact with an MCP server."
}

variable "adk_agent_instruction" {
  description = "The instruction (prompt) for the ADK agent."
  type        = string
  default     = "You are a helpful agent who can answer user questions by using the tools available from the MCP server."
}

variable "adk_agent_include_thoughts" {
  description = "Whether to include thoughts in the ADK agent's planning."
  type        = bool
  default     = false
}

variable "adk_agent_thinking_budget" {
  description = "The thinking budget for the ADK agent's planner."
  type        = number
  default     = 0
}
