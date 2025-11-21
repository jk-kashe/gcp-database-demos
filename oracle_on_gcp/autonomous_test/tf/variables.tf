variable "project_id" {
  type        = string
  description = "Project ID to deploy to (if using existing project) or base name for new project."
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID."
}

variable "region" {
  type        = string
  description = "Region to deploy to."
}

variable "zone" {
  type        = string
  description = "Zone to deploy to."
}

variable "create_new_project" {
  type        = bool
  description = "Whether to create a new project."
  default     = false
}

variable "oracle_adb_instance_name" {
  type        = string
  description = "Name of Oracle Autonomous Database instance."
  default     = "adb-test"
}
