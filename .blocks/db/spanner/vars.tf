variable "spanner_instance_name" {
  type        = string
  description = "Spanner Instance Name"
  default     = "demo-cluster"
}

variable "spanner_database_name" {
  type        = string
  description = "Spanner Database Name"
  default     = "demo-database"
}

variable "spanner_nodes" {
  type        = number
  description = "Number of Spanner nodes"
  default     = 1
}

variable "spanner_config" {
  type        = string
  description = "Spanner instance type"
  default     = null
}