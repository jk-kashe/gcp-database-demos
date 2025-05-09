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