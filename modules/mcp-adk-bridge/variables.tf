variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The region to provision resources in."
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service for the ADK agent."
  type        = string
  default     = "mcp-adk-bridge"
}

variable "mcp_toolbox_url" {
  description = "The URL of the MCP toolbox service."
  type        = string
}

variable "invoker_users" {
  description = "A list of user emails to grant invoker role to the Cloud Run service. e.g. ['user:foo@example.com']"
  type        = list(string)
  default     = []
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