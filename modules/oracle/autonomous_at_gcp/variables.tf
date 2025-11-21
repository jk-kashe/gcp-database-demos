variable "project_id" {
  type        = string
  description = "The project ID to deploy to."
}

variable "region" {
  type        = string
  description = "The region to deploy to."
}

variable "network_id" {
  type        = string
  description = "The ID (self_link) of the VPC network to peer with the Autonomous Database."
}

variable "oracle_adb_instance_name" {
  type        = string
  description = "Name of Oracle Autonomous Database instance."
  default     = "adb"
}

variable "oracle_adb_database_name" {
  type        = string
  description = "Name of Oracle Autonomous Database database."
  default     = "coffee"
}

variable "oracle_subnet_cidr_range" {
  type        = string
  description = "CIDR range for Oracle Autonomous Database."
  default     = "172.17.1.0/24"
}

variable "oracle_compute_count" {
  type        = number
  description = "Cores to use for Oracle Autonomous Database."
  default     = 2
}

variable "oracle_data_storage_size" {
  type        = number
  description = "Storage for Oracle Autonomous Database in GB."
  default     = 20
}

variable "oracle_database_version" {
  type        = string
  description = "Oracle Autonomous Database version."
  default     = "23ai"
}
