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

variable "create_new_project" {
  type        = bool
  description = "Whether to create a new project or use an existing one"
  default     = false # By default, we use an existing project
}

variable "provision_vpc_connector" {
  type        = bool
  description = "Whether to provision a Serverless VPC Access connector."
  default     = false
}

variable "vpc_connector_ip_cidr_range" {
  type        = string
  description = "The IP CIDR range for the VPC connector."
  default     = "10.8.0.0/28"
}

variable "vpc_connector_min_throughput" {
  type        = number
  description = "The minimum throughput for the VPC connector."
  default     = 200
}

variable "vpc_connector_max_throughput" {
  type        = number
  description = "The maximum throughput for the VPC connector."
  default     = 300
}

variable "additional_apis" {
  type        = list(string)
  description = "A list of additional APIs to enable in the project."
  default     = []
}