variable "app_repo" {
  type        = string
  description = "App repository"
  default     = "https://github.com/tombotch/genai-databases-retrieval-app"
}

variable "app_repo_revision" {
  type        = string
  description = "App repository revision"
  default     = "main"
}

variable "app_repo_path" {
  type        = string
  description = "App repository path"
  default     = "retrieval_service"
}