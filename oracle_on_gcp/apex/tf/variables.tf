variable "project_id" {
  type        = string
  description = "Project to deploy to"
}

variable "region" {
  type        = string
  description = "Region to deploy to"
}

variable "apis" {
  type        = list(string)
  description = "APIs to enable"
  default = [
    "aiplatform.googleapis.com",
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC to deploy"
  default     = "ora"
}

variable "subnet_cidr_range" {
  type        = string
  description = "CIDR range for subnet"
  default     = "172.16.1.0/24"
}

variable "vm_machine_type" {
  type        = string
  description = "Machine type for the Oracle VM"
  default     = "e2-medium"
}

variable "vm_image" {
  type        = string
  description = "OS Image for the Oracle VM"
  default     = "debian-cloud/debian-11"
}

variable "vm_oracle_password" {
  type        = string
  description = "Password for the Oracle database on the VM"
  sensitive   = true
}
