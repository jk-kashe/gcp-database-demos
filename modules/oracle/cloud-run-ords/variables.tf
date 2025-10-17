variable "project_id" {
  type        = string
  description = "The project ID to deploy to."
}

variable "region" {
  type        = string
  description = "The region to deploy to."
}

variable "apis" {
  type        = list(string)
  description = "The APIs to enable."
  default = [
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

variable "vm_oracle_password" {
  type        = string
  description = "The password for the Oracle database."
}

variable "db_user_password" {
  type        = string
  description = "The password for the internal database users (like ORDS_PUBLIC_USER)."
}

variable "oracle_db_ip" {
  type        = string
  description = "The IP address of the Oracle database."
}

variable "vpc_connector_id" {
  type        = string
  description = "The ID of the VPC connector."
}

variable "db_instance_dependency" {
  description = "This is not a real variable, just a way to enforce dependencies.  This should be a comma separated list of resources that need to be created before this module is called."
  type        = any
  default     = null
}

variable "iam_dependency" {
  description = "This is not a real variable, just a way to enforce dependencies.  This should be a comma separated list of resources that need to be created before this module is called."
  type        = any
  default     = null
}