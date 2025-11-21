variable "project_id" {
  type        = string
  description = "The project ID."
}

variable "project_number" {
  type        = string
  description = "The project number."
}

variable "region" {
  type        = string
  description = "The region."
}

variable "zone" {
  type        = string
  description = "The zone."
}

variable "network_id" {
  type        = string
  description = "The network ID (self link)."
}

variable "clientvm_name" {
  type        = string
  description = "The name of the client VM."
  default     = "oracle-client"
}

variable "project_services_dependency" {
  type        = any
  description = "Dependency to ensure APIs are enabled."
  default     = []
}
