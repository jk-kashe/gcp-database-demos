
variable "spanner_instance_name" {
  type        = string
  description = "Spanner Instance Name"
  default     = "demo-cluster"
}

variable "spanner_edition" {
  type        = string
  description = "Spanner Edition"
  default     = "STANDARD"

}

variable "spanner_database_name" {
  type        = string
  description = "Spanner Database Name"
  default     = "Demo Database"
}