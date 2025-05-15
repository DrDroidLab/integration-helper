# main.tf

# Create the Service Account
resource "google_service_account" "service_account" {
  project      = var.project_id
  account_id   = var.sa_name
  display_name = var.sa_name
  description  = "Service account for Playbooks integration, managed by Terraform."
}

# Assign IAM roles to the Service Account
resource "google_project_iam_member" "sa_roles" {
  for_each = toset(var.roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.service_account.email}"
}

# Create a JSON key for the Service Account
resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.service_account.name
  public_key_type  = "TYPE_X509_PEM_FILE" # For JSON key, private_key_type is implicitly TYPE_GOOGLE_CREDENTIALS_FILE
  key_algorithm      = var.key_algorithm
} 