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

variable "test_mode" {
  type        = bool
  description = "Test mode"
  default     = false
}

variable "create_new_project" {
  type        = bool
  description = "Whether to create a new project or use an existing one"
  default     = false # By default, we use an existing project
}
variable "alloydb_password" {
  type        = string
  description = "AlloyDB Password"
}
variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "alloydb-client"
}
variable "alloydb_primary_cpu_count" {
  type    = number
  default = 8
}

variable "alloydb_subscription_type" {
  type    = string
  default = "TRIAL"
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
variable "agentspace_retrieval_service_repo" {
  type        = string
  description = "App repository"
  default     = "https://github.com/tombotch/genai-databases-retrieval-app"
}

variable "agentspace_retrieval_service_repo_revision" {
  type        = string
  description = "App repository revision"
}

variable "agentspace_retrieval_service_repo_path" {
  type        = string
  description = "App repository path"
  default     = "retrieval_service"
}

variable "agentspace_location" {
  type        = string
  description = "Agentpsace location"
  default     = "global"
}



variable "agentspace_alloydb_database_name" {
  type        = string
  description = "Agentpsace AlloyDB Database Name"
  default     = "assistantdemo"
}

variable "agentspace_alloydb_database_user_name" {
  type        = string
  description = "Agentpsace AlloyDB Database User Name"
  default     = "agent"
}

variable "agentspace_alloydb_database_user_password" {
  type        = string
  description = "Agentpsace AlloyDB Database User Password"
  default     = "agent-777"
}

variable "agentspace_alloydb_database_nl_config_id" {
  type        = string
  description = "Agentpsace AlloyDB Database Natural Language Config Id"
  default     = "agentspace_demo_cfg"
}
