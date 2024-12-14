#if landing zone is used stand-alone, this should be included
variable "clientvm-name" {
  type        = string
  description = "Client VM name"
  default     = "demo-database-client"
}