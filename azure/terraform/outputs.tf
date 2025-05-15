output "subscription_id" {
  description = "The ID of the Azure subscription"
  value       = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  description = "The Azure tenant ID"
  value       = data.azurerm_subscription.current.tenant_id
}

output "client_id" {
  description = "The application (client) ID"
  value       = azuread_application.log_analytics_app.client_id
  sensitive   = false
}

output "client_secret" {
  description = "The client secret for the application"
  value       = azuread_application_password.log_analytics_app_password.value
  sensitive   = true
} 