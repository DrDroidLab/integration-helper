# Configure Azure providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}

# Get current subscription details
data "azurerm_subscription" "current" {}

# Create Azure AD application
resource "azuread_application" "log_analytics_app" {
  display_name = var.app_name
  
  # Required API permissions
  required_resource_access {
    resource_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013" # Azure Service Management API

    resource_access {
      id   = "41094075-9dad-400e-a0bd-54e686782033" # user_impersonation
      type = "Scope" # Delegated permission
    }
  }

  required_resource_access {
    resource_app_id = "ca7f3f0b-7d91-482c-8e09-c5d840d0eac5" # Log Analytics API

    resource_access {
      id   = "73c7b4b0-5cd3-4efd-b947-62fe4185be46" # Data.Read
      type = "Role" # Application permission
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope" # Delegated permission
    }
  }
}

# Create service principal associated with the application
resource "azuread_service_principal" "log_analytics_sp" {
  client_id = azuread_application.log_analytics_app.client_id
}

# Create client secret for the application
resource "azuread_application_password" "log_analytics_app_password" {
  application_object_id = azuread_application.log_analytics_app.object_id
  display_name          = "LogAnalyticsTerraformSecret"
  end_date              = "2099-01-01T00:00:00Z"
}


# Assign roles to the service principal

# 1. Monitoring Reader role
resource "azurerm_role_assignment" "monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.log_analytics_sp.object_id
  skip_service_principal_aad_check = true
}

# 2. Log Analytics Reader role
resource "azurerm_role_assignment" "log_analytics_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azuread_service_principal.log_analytics_sp.object_id
  skip_service_principal_aad_check = true
} 