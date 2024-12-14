variable "demo_project_id" {
  type        = string
  description = "New Cloud Project ID for this demo. Choose a unique ID (letters, numbers, hyphens)"
}

variable "billing_account_id" {
  type        = string
  description = "Billing account id associated with this project"
}

variable "region" {
  type        = string
  description = "Your Google Cloud Region"
}

variable "zone" {
  type        = string
  description = "Your Google Cloud zone"
}

variable "test_mode" {
  type        = bool
  description = "Test mode"
  default     = false
}

variable "create_new_project" {
  type        = bool
  description = "Whether to create a new project or use an existing one"
  default     = false # By default, we use an existing project
}
variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "alloydb-client"
}
variable "alloydb_password" {
  type        = string
  description = "AlloyDB Password"
}
variable "alloydb_primary_cpu_count" {
  type    = number
  default = 8
}

variable "alloydb_subscription_type" {
  type    = string
  default = "TRIAL"
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
variable "demo_app_support_email" {
  type        = string
  description = "Demo App Support email"
}
