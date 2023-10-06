output "id" {
  value       = azurerm_key_vault.kv_for_app.id
  description = "The ID of the Key Vault."
}

output "name" {
  value       = azurerm_key_vault.kv_for_app.name
  description = "The name of the Key Vault."
}

output "sql_username" {
  value     = data.azurerm_key_vault_secret.sql_username
  sensitive = true
}

output "sql_password" {
  value     = data.azurerm_key_vault_secret.sql_password
  sensitive = true
}