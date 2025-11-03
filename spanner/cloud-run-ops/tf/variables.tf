variable "demo_project_id" {
  type        = string
  description = "New Cloud Project ID for this demo. Choose a unique ID (letters, numbers, hyphens)"
}

variable "billing_account_id" {
  type        = string
  description = "Billing account id associated with this project"
}

variable "regions" {
  type        = list(string)
  description = "Your Google Cloud Regions"
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
  default     = "spanner-client"
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

variable "spanner_edition" {
  type        = string
  description = "Spanner Edition"
  default     = "ENTERPRISE"
}

variable "spanner_nodes" {
  type        = number
  description = "Number of Spanner nodes to provision"
  default     = 0.1

}

variable "spanner_config" {
  type        = string
  description = "Spanner configuration"
  default     = null
}

variable "demo_hostname" {
  type        = string
  description = "Hostname to use for demo LB"
}

variable "dns_project_id" {
  type        = string
  description = "Project containing the Google-managed DNS zones"
  default     = null
}

variable "dns_zone_name" {
  type        = string
  description = "Name of the DNS zone"
}

variable "demo_users" {
  type        = set(string)
  description = "IAP users for the app"
  default     = []
}