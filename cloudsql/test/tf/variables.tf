### FILE_PATH: variables.tf ###
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
variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "cloudsql-client" # Renamed default for clarity
}

# --- Cloud SQL Variables ---
variable "db_password" {
  type        = string
  description = "Cloud SQL database Password for the default 'postgres' user"
  sensitive   = true # Mark password as sensitive
}

variable "db_instance_name" {
  type        = string
  description = "Cloud SQL Instance Name"
  default     = "cloudsql-pg-instance"
}

variable "db_name" {
  type        = string
  description = "Name of the database to create within the Cloud SQL instance"
  default     = "assistantdemo"
}

variable "db_tier" {
  type        = string
  description = "The machine type (tier) for the Cloud SQL instance (e.g., db-custom-2-4096)"
  default     = "db-f1-micro" # Choose an appropriate tier, f1-micro is small
}

variable "db_disk_size" {
  type        = number
  description = "The disk size for the Cloud SQL instance in GB"
  default     = 20
}

# --- End Cloud SQL Variables ---

variable "demo_app_support_email" {
  type        = string
  description = "Demo App Support email"
}