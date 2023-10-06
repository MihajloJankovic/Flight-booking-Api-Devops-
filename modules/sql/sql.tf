variable "resource_group" {
  type = string
}

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

variable "sql_version" {
  type = string
}

variable "sql_login" {

}

variable "sql_password" {

}

variable "sqldb_sku_name" {
  type = string
}

variable "sqldb_sku_max_gb_size" {
  type = number
}

variable "subneta_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "app_source_address" {
  type = string
}

variable "logging" {
  type = string
}


data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_mssql_server" "sql-planepal-dev-neu-01" {
  name                         = "sql${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
  resource_group_name          = var.resource_group
  location                     = var.location
  version                      = var.sql_version
  administrator_login          = var.sql_login.value
  administrator_login_password = var.sql_password.value

  timeouts {
    create = "2h30m"
    update = "2h"
    delete = "20m"
  }

}

resource "azurerm_mssql_firewall_rule" "FirewallRule" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sql-planepal-dev-neu-01.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "FirewallRule1" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sql-planepal-dev-neu-01.id
  start_ip_address = chomp(data.http.myip.body)
  end_ip_address   = chomp(data.http.myip.body)
}

resource "azurerm_mssql_database" "sqldb-planepal-dev-neu-01" {
  name        = "sqldb${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
  sku_name    = var.sqldb_sku_name
  collation   = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = var.sqldb_sku_max_gb_size
  server_id   = azurerm_mssql_server.sql-planepal-dev-neu-01.id

  timeouts {
    create = "2h30m"
    update = "2h"
    delete = "20m"
  }

  tags = {
    environment = "development"
  }
}

# resource "azurerm_mssql_virtual_network_rule" "sqlvnetrule" {
#   name                = "sql-vnet-rule${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
#   resource_group_name = var.resource_group
#   server_name         = azurerm_mssql_server.sql-planepal-dev-neu-01.name
#   subnet_id           = var.subneta_id
# }

resource "azurerm_network_security_group" "st_sql_nsg" {
  name                = "nsg-sql-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-app"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 200
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_ranges    = [1433]
    source_address_prefix      = var.app_source_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = var.subneta_id
  network_security_group_id = azurerm_network_security_group.st_sql_nsg.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_st_dns_zone_vnet_link" {
  name                  = "nl-${lower(var.app_name)}-${var.environment}-${var.location}-03"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = var.vnet_id
}


resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_endpoint" "sql_endpoint" {
  name                = "pep-sql-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subneta_id

  private_dns_zone_group {
    name                 = "sql-${var.environment}-dns-zone-group-01"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }

  private_service_connection {
    name                           = "sql-${var.environment}-privateserviceconnection-01"
    private_connection_resource_id = azurerm_mssql_server.sql-planepal-dev-neu-01.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
  depends_on = [azurerm_mssql_database.sqldb-planepal-dev-neu-01]
}

data "azurerm_monitor_diagnostic_categories" "sql_cat" {
  resource_id = azurerm_mssql_database.sqldb-planepal-dev-neu-01.id
}

resource "azurerm_monitor_diagnostic_setting" "sql_diag" {
  name                       = "sql-diag"
  target_resource_id         = azurerm_mssql_database.sqldb-planepal-dev-neu-01.id
  log_analytics_workspace_id = var.logging

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.sql_cat.logs

    content {
      category = log.value
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.sql_cat.metrics

    content {
      category = metric.value
    }
  }
}
