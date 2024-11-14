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

variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "alloydb-client"
}

variable "test_mode" {
  type        = bool
  description = "Test mode"
  default     = false
}