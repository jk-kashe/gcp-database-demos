variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the service."
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
}

variable "container_image" {
  description = "The Docker container image to deploy."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account the Cloud Run service will run as."
  type        = string
}

variable "invoker_users" {
  description = "A list of members (e.g., `user:me@example.com`) who should be granted access to the service."
  type        = list(string)
  default     = []
}

variable "vpc_connector_id" {
  description = "The ID of a VPC connector for the service to use."
  type        = string
  default     = null
}

variable "container_args" {
  description = "Arguments to pass to the container."
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Port to expose from the container."
  type        = number
  default     = 8080
}

variable "template_volumes" {
  description = "A list of volume definitions for the service template. See the 'google_cloud_run_v2_service' resource documentation for the expected structure."
  type        = any
  default     = []
}

variable "container_volume_mounts" {
  description = "A list of volume mounts for the container. See the 'google_cloud_run_v2_service' resource documentation for the expected structure."
  type        = any
  default     = []
}

variable "env_vars" {
  description = "A list of environment variable objects for the container. Each object should have a 'name' and either a 'value' or a 'value_source' block."
  type        = any
  default     = []
}
