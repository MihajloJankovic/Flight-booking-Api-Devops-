output "blob_endpoint" {
  value = azurerm_storage_account.storage_account.primary_blob_endpoint
}

output "account_id" {
  value = azurerm_storage_account.storage_account.id
}

output "name" {
  value = azurerm_storage_account.storage_account.name
}