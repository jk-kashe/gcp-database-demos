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