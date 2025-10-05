variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "project_number" {
  description = "The number of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
}

variable "zone" {
  description = "The GCP zone."
  type        = string
}

variable "network_id" {
  description = "The ID of the network to attach the VM to."
  type        = string
}

variable "clientvm-name" {
  description = "The name of the client VM."
  type        = string
  default     = "alloydb-client"
}

variable "project_services_dependency" {
  description = "Dependency on project services being enabled."
  type        = any
  default     = null
}
