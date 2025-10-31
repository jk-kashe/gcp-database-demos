variable "project_id" {
  type        = string
  description = "Project to deploy to"
}

variable "region" {
  type        = string
  description = "Region to deploy to"
}

variable "vm_oracle_password" {
  type        = string
  description = "Password for the Oracle database on the VM"
  sensitive   = true
}

variable "billing_account_id" {
  type        = string
  description = "Billing account id associated with this project"
}

variable "apex_workspace" {
  type        = string
  description = "The name of the APEX workspace."
  default     = "DEMO"
}

variable "apex_schema" {
  type        = string
  description = "The name of the database schema for the APEX workspace."
  default     = "WKSP_DEMO"
}

variable "apex_user" {
  type        = string
  description = "The name of the APEX workspace administrator user."
  default     = "DEMO"
}