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
