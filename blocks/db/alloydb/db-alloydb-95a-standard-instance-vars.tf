variable "alloydb_primary_cpu_count" {
  type        = number
  default     = 2
}

variable "alloydb_subscription_type" {
  type        = string
  default     = "STANDARD"
}

variable "alloydb_cluster_name" {
  type        = string
  description = "AlloyDB Cluster Name"
  default     = "alloydb-demo-cluster"
}

variable "alloydb_primary_name" {
  type        = string
  description = "AlloyDB Primary Name"
  default     = "alloydb-demo-cluster-primary"
}
