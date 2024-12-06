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