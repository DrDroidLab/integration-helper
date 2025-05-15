# outputs.tf

output "service_account_email" {
  description = "The email address of the created service account."
  value       = google_service_account.service_account.email
}

output "service_account_name" {
  description = "The full name of the created service account."
  value       = google_service_account.service_account.name
}

output "project_id_used" {
  description = "The GCP Project ID where the resources were created."
  value       = var.project_id
}

output "service_account_key_json" {
  description = "The JSON private key for the service account. IMPORTANT: This is sensitive."
  value       = base64decode(google_service_account_key.sa_key.private_key)
  sensitive   = true
}

output "service_account_key_id" {
  description = "The ID of the service account key."
  value       = google_service_account_key.sa_key.id
} 