output "instrumentation_key" {
  value = azurerm_application_insights.app_insights.instrumentation_key
}

output "id" {
  value       = azurerm_log_analytics_workspace.log-a-w.id
  description = "The ID of log analytics workspace."
}