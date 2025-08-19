variable "finance_advisor_commit_id" {
  type        = string
  description = "Finance Advisor repo commit ID"
}

variable "run_iap" {
  type        = bool
  description = "Use IAP for Cloud Run"
  default     = false
}