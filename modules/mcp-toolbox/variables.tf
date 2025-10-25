variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The region to provision resources in."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network to connect to."
  type        = string
}

variable "tools_yaml_content" {
  description = "The content of the tools.yaml file for the MCP toolbox."
  type        = string
  sensitive   = true
}

variable "service_name" {
  description = "The name of the Cloud Run service for the MCP toolbox."
  type        = string
  default     = "mcp-toolbox"
}

variable "service_account_id" {
  description = "The account id for the service account."
  type        = string
  default     = "mcp-toolbox-identity"
}

variable "extra_service_account_roles" {
  description = "A list of extra IAM roles to grant to the service account."
  type        = list(string)
  default     = []
}

variable "invoker_users" {
  description = "A list of user emails to grant invoker role to the Cloud Run service. e.g. ['user:foo@example.com']"
  type        = list(string)
  default     = []
}

variable "container_image" {
  description = "The container image to deploy."
  type        = string
  default     = "us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:latest"
}

variable "vpc_connector_id" {
  description = "The ID of an existing VPC Access Connector."
  type        = string
  default     = null
}

variable "current_user_email" {
  type        = string
  description = "Email of the current user to grant IAP access."
}

