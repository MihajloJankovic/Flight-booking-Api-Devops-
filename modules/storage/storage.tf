variable "resource_group" {
  description = "Resource group name"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "account_tier" {
  description = "Account tier"
  type        = string
}

variable "replication_type" {
  description = "Replication type"
  type        = string
}

variable "location" {
  description = "Location"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "outbound_ip_address_list" {
  description = "List of ips used by app service"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "levi9_public_ip" {
  type = string
}

variable "vnet_id" {
  description = "Virtual network ID"
  type        = string
}

variable "logging" {
  type = string
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "st${lower(var.app_name)}${var.environment}01"
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
}

resource "azurerm_storage_container" "storage_container" {
  name                 = "sc-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  storage_account_name = azurerm_storage_account.storage_account.name
}

resource "azurerm_private_endpoint" "storage_account_endpoint" {
  name                = "pe-st-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "storage-account-connection-01"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pe-st-${lower(var.app_name)}-${var.environment}-${var.location}-dns-zone-group-01"
    private_dns_zone_ids = [azurerm_private_dns_zone.app_st_dns_zone.id]
  }
}

resource "azurerm_network_security_group" "st_app_nsg" {
  name                = "nsg-st-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-app"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 150
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefixes    = var.outbound_ip_address_list
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-levi9"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 151
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = var.levi9_public_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.st_app_nsg.id
}

resource "azurerm_private_dns_zone" "app_st_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_st_dns_zone_vnet_link" {
  name                  = "nl-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.app_st_dns_zone.name
  virtual_network_id    = var.vnet_id
}

data "azurerm_monitor_diagnostic_categories" "st_acc_cat" {
  resource_id = azurerm_storage_account.storage_account.id
}

resource "azurerm_monitor_diagnostic_setting" "st_acc_diag" {
  name                       = "st_acc-diag"
  target_resource_id         = azurerm_storage_account.storage_account.id
  log_analytics_workspace_id = var.logging

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.st_acc_cat.logs

    content {
      category = log.value
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.st_acc_cat.metrics

    content {
      category = metric.value
    }
  }
}

