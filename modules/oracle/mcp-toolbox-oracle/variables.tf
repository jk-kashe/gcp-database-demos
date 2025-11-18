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

variable "service_name" {
  description = "The name of the Cloud Run service for the MCP toolbox."
  type        = string
  default     = "mcp-toolbox-oracle"
}


variable "oracle_host" {
  description = "The hostname or IP address of the Oracle database."
  type        = string
}

variable "oracle_port" {
  description = "The port number of the Oracle database."
  type        = number
  default     = 1521
}

variable "oracle_user" {
  description = "The username for the Oracle database."
  type        = string
}

variable "oracle_password" {
  description = "The password for the Oracle database."
  type        = string
  sensitive   = true
}

variable "oracle_service" {
  description = "The service name of the Oracle database."
  type        = string
}

variable "vpc_connector_id" {
  description = "The ID of an existing VPC Access Connector."
  type        = string
  default     = null
}

variable "invoker_users" {
  description = "A list of user emails to grant invoker role to the Cloud Run service. e.g. ['user:foo@example.com']"
  type        = list(string)
  default     = []
}
