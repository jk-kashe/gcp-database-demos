variable "project_id" {
  type        = string
  description = "The project ID to deploy to."
}

variable "region" {
  type        = string
  description = "The region to deploy to."
}

variable "service_name" {
  description = "The name of the Cloud Run service for the MCP toolbox."
  type        = string
  default     = "ords"
}

variable "service_account_id" {
  description = "The account id for the service account."
  type        = string
  default     = "ords-identity"
}

variable "invoker_users" {
  description = "A list of user emails to grant invoker role to the Cloud Run service. e.g. ['user:foo@example.com']"
  type        = list(string)
  default     = []
}

variable "vm_oracle_password" {
  type        = string
  description = "The password for the Oracle database."
  sensitive   = true
}

variable "db_user_password" {
  type        = string
  description = "The password for the internal database users (like ORDS_PUBLIC_USER)."
  sensitive   = true
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

variable "ords_container_tag" {
  type        = string
  description = "The container tag for the ORDS image, derived from the VM installation."
}

variable "gcs_bucket_name" {
  type        = string
  description = "The name of the GCS bucket where the ORDS config is stored."
  default     = null
}

variable "container_resources" {
  description = "Container resource limits."
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
}
