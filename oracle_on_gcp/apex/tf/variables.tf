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

variable "oracle_adb_instance_name" {
  type        = string
  description = "Name of Oracle Autonomous Database instance"
  default     = "adb"
}

variable "oracle_adb_database_name" {
  type        = string
  description = "Name of Oracle Autonomous Database database"
  default     = "coffee"
}

variable "oracle_subnet_cidr_range" {
  type        = string
  description = "CIDR range for Oracle Autonomous Database"
  default     = "172.17.1.0/24"
}

variable "oracle_compute_count" {
  type        = number
  description = "Cores to use for Oracle Autonomous Database"
  default     = 2
}

variable "oracle_data_storage_size" {
  type        = number
  description = "Storage for Oracle Autonomous Database"
  default     = 20
}

variable "oracle_database_version" {
  type        = string
  description = "Oracle Autonomous Database version"
  default     = "23ai"
}

variable "git_repo" {
  type        = string
  description = "The Git repo URL"
  default     = "https://github.com/jk-kashe/oracledb-vertexai-demo.git"
}

variable "git_branch" {
  type        = string
  description = "The Git branch to checkout"
  default     = "autonomous-run"
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
