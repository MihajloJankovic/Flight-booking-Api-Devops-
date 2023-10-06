variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "location_abbreviation" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = string
}

variable "subnets" {
  type = map(object({
    name                = string
    resource_group_name = string
    address_prefixes    = string
  }))
}


resource "azurerm_virtual_network" "az_vNet" {
  name                = "vnet-${var.app_name}-${var.environment}-${var.location}-01"
  address_space       = [var.address_space]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "az_subnet" {
  for_each                                  = var.subnets
  name                                      = each.value.name
  resource_group_name                       = each.value.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.az_vNet.name
  address_prefixes                          = [each.value.address_prefixes]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "appservice_subnet" {
  name                                      = "snet-${var.app_name}-${var.environment}-${var.location_abbreviation}-06"
  resource_group_name                       = var.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.az_vNet.name
  address_prefixes                          = ["10.0.5.0/24"]
  private_endpoint_network_policies_enabled = true

  delegation {
    name = "app-vnet-delegation-01"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}





