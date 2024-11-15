variable "alloydb_primary_cpu_count" {
  type        = number
  default     = 8
}

variable "alloydb_subscription_type" {
  type        = string
  default     = "TRIAL"
}

variable "alloydb_cluster_name" {
  type        = string
  description = "AlloyDB Cluster Name"
  default     = "alloydb-trial-cluster"
}

variable "alloydb_primary_name" {
  type        = string
  description = "AlloyDB Primary Name"
  default     = "alloydb-trial-cluster-primary"
}
