output "tenant_id" {
  value = azurerm_windows_web_app.app-PlanePal-dev-northeurope-00.identity[0].tenant_id
}

output "object_id" {
  value = azurerm_windows_web_app.app-PlanePal-dev-northeurope-00.identity[0].principal_id
}

output "web_app_id" {
  value = azurerm_windows_web_app.app-PlanePal-dev-northeurope-00.id
}

output "outbound_ip_address_list" {
  value = azurerm_windows_web_app.app-PlanePal-dev-northeurope-00.outbound_ip_address_list
}

output "app_service_plan_id" {
  value = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
}