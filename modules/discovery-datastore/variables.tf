variable "project_id" {
  type        = string
  description = "The project ID to deploy the data store to."
}

variable "location" {
  type        = string
  description = "The location for the data store."
}

variable "instance_path" {
  type        = string
  description = "The AlloyDB instance path."
}

variable "database_name" {
  type        = string
  description = "The AlloyDB database name."
}

variable "database_user_name" {
  type        = string
  description = "The AlloyDB database user name."
}

variable "database_user_password" {
  type        = string
  description = "The AlloyDB database user password."
  sensitive   = true
}

variable "nl_config_id" {
  type        = string
  description = "The AlloyDB NL config ID."
}

variable "datastore_id" {
  type        = string
  description = "The ID of the data store."
}

variable "project_services_dependency" {
  type = any
  description = "Dependency to ensure project services are enabled."
  default = []
}

variable "script_dir" {
  type        = string
  description = "The directory path to create the datastore creation script in."
}

variable "agentspace_location" {
  type        = string
  description = "Agentpsace location"
  default     = "global"
}
