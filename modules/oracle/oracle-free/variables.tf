variable "project_id" {
  type        = string
  description = "The project ID to deploy to."
}

variable "network_name" {
  type        = string
  description = "The name of the network to deploy to."
}

variable "network_id" {
  type        = string
  description = "The ID of the network to deploy to."
}

variable "subnetwork_id" {
  type        = string
  description = "The ID of the subnetwork to deploy to."
  default     = null
}

variable "zone" {
  type        = string
  description = "The zone to deploy to."
}

variable "vm_machine_type" {
  type        = string
  description = "The machine type for the VM."
  default     = "e2-standard-4"
}

variable "vm_image" {
  type        = string
  description = "The image for the VM."
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "vm_oracle_password" {
  type        = string
  description = "The password for the Oracle database."
}

variable "client_script_path" {
  type        = string
  description = "The local path to write the sqlplus.sh script to."
  default     = null
}

variable "gcs_bucket_name" {
  type        = string
  description = "The name of the GCS bucket to store the ORDS config in"
  default     = null
}

variable "additional_db_users" {
  description = "A list of additional database users to create."
  type = list(object({
    username = string
    grants   = list(string)
  }))
  default = []
}

variable "ords_version" {
  description = "The specific version of the ORDS RPM package to install. If empty, the latest version will be installed."
  type        = string
  default     = "25.3.0"
}

variable "oracle_free_tag" {
  description = "The Docker image tag for the Oracle Free Database."
  type        = string
  default     = "23.9.0.0"
}

variable "apex_download_url" {
  description = "The URL to download the APEX zip file from."
  type        = string
  default     = "https://download.oracle.com/otn_software/apex/apex_24.2.zip"
}

variable "allowed_source_ranges" {
  description = "A list of source IP ranges to allow access to the Oracle VM. If null, defaults to the VM's subnetwork."
  type        = list(string)
  default     = null
}
