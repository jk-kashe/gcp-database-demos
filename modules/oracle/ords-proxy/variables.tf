variable "project_id" {
  type        = string
  description = "The project ID."
}

variable "region" {
  type        = string
  description = "The region."
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service."
  default     = "ords-proxy"
}

variable "ords_uri" {
  type        = string
  description = "The full ORDS URI of the Autonomous Database (e.g., https://xyz.oraclecloudapps.com/ords/)."
}

variable "vpc_connector_id" {
  type        = string
  description = "The VPC Connector ID to access the private ADB."
}

variable "invoker_users" {
  type        = list(string)
  description = "List of users/groups allowed to invoke the service (e.g., ['user:me@example.com'])."
  default     = []
}

variable "use_iap" {
  type        = bool
  description = "Whether to enable IAP for the service."
  default     = true
}

variable "iam_dependency" {
  type        = any
  description = "A resource to depend on before starting the container build, to ensure IAM permissions are propagated."
  default     = null
}

variable "gcs_staging_bucket" {
  type        = string
  description = "GCS bucket to use for Cloud Build source staging. If not provided, the default bucket is used."
  default     = ""
}
