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
variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "spanner-client"
}
variable "spanner_edition" {
  type        = string
  description = "Spanner Edition"
  default     = "STANDARD"

}
