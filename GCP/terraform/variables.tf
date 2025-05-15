variable "project_id" {
  description = "The Google Cloud Project ID to deploy resources in."
  type        = string
}

variable "sa_name" {
  description = "The desired name for the service account (e.g., 'playbooks-integration')."
  type        = string
  default     = "playbooks-logs-viewer"
}

variable "roles" {
  description = "A list of IAM roles to assign to the service account."
  type        = list(string)
  default     = ["roles/logging.viewer", "roles/monitoring.viewer"]
}

variable "key_algorithm" {
  description = "The algorithm to use for the service account key."
  type        = string
  default     = "KEY_ALG_RSA_2048"
} 