variable "project_id" {
  type        = string
  description = "The ID of the GCP project."
}

variable "project_number" {
  type        = string
  description = "The number of the GCP project."
}

variable "region" {
  type        = string
  description = "The GCP region."
}

variable "zone" {
  type        = string
  description = "The GCP zone."
}

variable "alloydb_cluster_name" {
  type        = string
  description = "AlloyDB Cluster Name"
  default     = "alloydb-trial-cluster"
}

variable "alloydb_primary_name" {
  type        = string
  description = "AlloyDB Primary Name"
  default     = "alloydb-trial-cluster-primary"
}

variable "alloydb_password" {
  type        = string
  description = "AlloyDB Password"
  sensitive   = true
}

variable "alloydb_subscription_type" {
  type    = string
  default = "TRIAL"
}

variable "alloydb_primary_cpu_count" {
  type    = number
  default = 8
}

variable "network_id" {
  type        = string
  description = "The ID of the VPC network to deploy AlloyDB into."
}

variable "clientvm_name" {
  type        = string
  description = "The name of the client VM."
}

variable "private_service_access_dependency" {
  type        = any
  description = "Dependency for the private service access connection."
  default     = null
}

variable "clientvm_boot_dependency" {
  type        = any
  description = "Dependency for the client VM boot."
  default     = null
}

variable "enable_service_usage_api_dependency" {
  type = any
  description = "Dependency for enabling service usage API."
  default = null
}

variable "client_script_path" {
  type        = string
  description = "The local path to write the alloydb-client.sh script to."
}

variable "enable_ai" {
  type        = bool
  description = "Enable AlloyDB AI features."
  default     = false
}