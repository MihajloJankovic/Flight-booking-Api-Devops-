output "subnet" {
  value = azurerm_subnet.az_subnet
}

output "vnet" {
  value = azurerm_virtual_network.az_vNet
}

output "appservice_subnet_id" {
  value = azurerm_subnet.appservice_subnet.id
}

output "appservice_subnet_address_prefixes" {
  value = azurerm_subnet.appservice_subnet.address_prefixes
}