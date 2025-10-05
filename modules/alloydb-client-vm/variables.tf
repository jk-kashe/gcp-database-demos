variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_id" {
  type = string
}

variable "clientvm-name" {
  type = string
}

variable "project_services_dependency" {
  description = "This is not a real variable, just a way to enforce dependencies.  This should be a comma separated list of resources that need to be created before this module is called."
  type        = any
  default     = null
}

variable "alloydb_instance_dependency" {
  description = "This is not a real variable, just a way to enforce dependencies.  This should be a comma separated list of resources that need to be created before this module is called."
  type        = any
  default     = null
}

variable "alloydb_cluster_name" {
  type = string
}

variable "alloydb_primary_name" {
  type = string
}

variable "alloydb_password" {
  type      = string
  sensitive = true
}

variable "alloydb_instance_ip" {
  type = string
}

variable "enable_ai" {
  type    = bool
  default = false
}

variable "client_script_path" {
  type        = string
  description = "The local path to write the alloydb-client.sh script to."
}
