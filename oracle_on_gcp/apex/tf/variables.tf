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
