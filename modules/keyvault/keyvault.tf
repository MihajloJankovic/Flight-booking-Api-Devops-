variable "location" {
  type        = string
  description = "location where zour resource needs provision in azure"
}

variable "resource_group" {
  type        = string
  description = "resource_group name"
}

variable "app_name" {
  type        = string
  description = "Name of Application"
}

variable "outbound_ip_address_list" {
  description = "List of ips used by app service"
}

variable "environment" {
  type        = string
  description = "Name of Environment"
}

variable "kv_app_sku_name" {
  type        = string
  description = "sku name for app key vault"
}

variable "tenant_id" {
  type = string
}

variable "principal_id" {
  type = string
}

variable "devops_kv_name" {
  type = string
}

variable "key_sql_username" {
  type        = string
  description = "Key for SQL username in DevOps database"
}

variable "key_sql_password" {
  type        = string
  description = "Key for SQL password in DevOps database"
}

variable "kv_base_URL_name" {
  type = string
}

variable "kv_base_URL" {
  type = string
}

variable "app_secrets_keys" {
  type = list(string)
}

variable "subneta_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "logging" {
  type = string
}

variable "levi9_public_ip" {
  type = string
}

variable "appservice_subnet_address_prefixes" {

}


data "azurerm_key_vault" "devops_kv" {
  name                = var.devops_kv_name
  resource_group_name = var.resource_group
}

data "azurerm_key_vault_secret" "sql_username" {
  name         = var.key_sql_username
  key_vault_id = data.azurerm_key_vault.devops_kv.id
}

data "azurerm_key_vault_secret" "sql_password" {
  name         = var.key_sql_password
  key_vault_id = data.azurerm_key_vault.devops_kv.id
}

# data "azurerm_key_vault_secret" "app_secrets" {
#   for_each = toset(var.app_secrets_keys)

#   name = each.key
#   key_vault_id = data.azurerm_key_vault.devops_kv.id
# }

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv_for_app" {
  name                       = "kvapp${lower(var.app_name)}${var.environment}02"
  location                   = var.location
  resource_group_name        = var.resource_group
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = 30
  purge_protection_enabled   = false

  sku_name = var.kv_app_sku_name

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.principal_id

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "f6ac4965-cbb9-40f7-a801-98cc25dd9177"

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Restore", "Recover", "Purge",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "d4098138-9b79-4120-b056-9a6e50406362"

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Restore", "Recover", "Purge",
    ]
  }

  network_acls {
    default_action = "Deny"

    # virtual_network_subnet_ids = [var.subneta_id]

    bypass = "AzureServices"

    ip_rules = concat(var.outbound_ip_address_list, [chomp(data.http.myip.body)], [var.levi9_public_ip])
  }
}

# resource "azurerm_key_vault_secret" "app_secrets" {
#   for_each = data.azurerm_key_vault_secret.app_secrets

#   name = each.value.name
#   value = each.value.value
#   key_vault_id = data.azurerm_key_vault.devops_kv.id
# }

# resource "azurerm_key_vault_secret" "kv_base_URL" {
#   name         = var.kv_base_URL_name
#   value        = var.kv_base_URL
#   key_vault_id = azurerm_key_vault.kv_for_app.id
#   depends_on = [
#     azurerm_key_vault.kv_for_app
#   ]
# }

resource "azurerm_private_endpoint" "kv_app_ep" {
  name                = "pep-${lower(var.app_name)}-${var.environment}-02"
  resource_group_name = var.resource_group
  location            = var.location
  subnet_id           = var.subneta_id
  private_dns_zone_group {
    name                 = "pep-kv-${lower(var.app_name)}-${var.environment}-${var.location}-dns-zone-group-01"
    private_dns_zone_ids = [azurerm_private_dns_zone.az_kv_dns_zone.id]

  }
  private_service_connection {
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.kv_for_app.id
    name                           = "${azurerm_key_vault.kv_for_app.name}-psc"
    subresource_names              = ["vault"]
  }
  depends_on = [azurerm_key_vault.kv_for_app]
}

resource "azurerm_private_dns_zone" "az_kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "az_kv_virtual_network_link" {
  name                  = "${azurerm_private_dns_zone.az_kv_dns_zone.name}-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.az_kv_dns_zone.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

resource "azurerm_network_security_group" "kv_app_nsg" {
  name                = "nsg-kv-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-app"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 102
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
    priority                   = 103
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = var.levi9_public_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-app-subnet"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 104
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefixes    = var.appservice_subnet_address_prefixes
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = var.subneta_id
  network_security_group_id = azurerm_network_security_group.kv_app_nsg.id
}

data "azurerm_monitor_diagnostic_categories" "kv_cat" {
  resource_id = azurerm_key_vault.kv_for_app.id
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_diag" {
  name                       = "kv-diag"
  target_resource_id         = azurerm_key_vault.kv_for_app.id
  log_analytics_workspace_id = var.logging

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.kv_cat.logs

    content {
      category = log.value
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.kv_cat.metrics

    content {
      category = metric.value
    }
  }
}