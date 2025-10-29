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