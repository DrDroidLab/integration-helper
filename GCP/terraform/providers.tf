terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # You can specify the project and region here,
  # or leave them to be picked up from the environment
  # (e.g., gcloud config get-value project)
  # project = var.project_id
  # region  = "us-central1" # Or your preferred region
} 