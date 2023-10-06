variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}
variable "app_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "location_abbreviation" {
  type = string
}
variable "aa_sku_name" {
  type = string
}
variable "aar_runbook_type" {
  type = string
}
variable "aar_log_verbose" {
  type = string
}
variable "aar_log_progress" {
  type = string
}
variable "aas_start_time" {
  type = string
}
variable "aas_timezone" {
  type = string
}
variable "st_account_tier" {
  type = string
}
variable "st_replication_type" {
  type = string
}
variable "sc_container_access_type" {
  type = string
}

variable "storage_account_name" {
  type = string
}

resource "azurerm_automation_account" "aaplanepaldevneu01" {
  name                = "aa${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.aa_sku_name
}

# resource "azurerm_automation_runbook" "aarplanepaldevneu01" {
#   name                  = "aar${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
#   automation_account_id = azurerm_automation_account.aaplanepaldevneu01.id
#   runbook_type          = var.aar_runbook_type
#   log_verbose           = var.aar_log_verbose
#   log_progress          = var.aar_log_progress

#   publish_content {
#     content = <<-EOT
#       param (
#           [string] $param1
#       )
#       //create sql user
#       //send backup to storage account
#       Write-Output "Hello, World!"
#       Write-Output "Param1 value: $param1"
#     EOT
#   }
# }

# resource "azurerm_automation_schedule" "aasplanepaldevneu01" {
#   name                    = "aas${lower(var.app_name)}${var.environment}${var.location_abbreviation}00"
#   resource_group_name     = var.resource_group_name
#   automation_account_name = azurerm_automation_account.aaplanepaldevneu01.name
#   # automation_account_id = azurerm_automation_account.aaplanepaldevneu01.id
#   start_time  = formatdate("yyyy-MM-ddT${var.aas_start_time}Z", timestamp())
#   description = "Run daily at ${var.aas_start_time} ${var.aas_timezone}"
#   timezone    = var.aas_timezone

#   # weekly {
#   #   monday    = true
#   #   tuesday   = true
#   #   wednesday = true
#   #   thursday  = true
#   #   friday    = true
#   # }

#   # runbook {
#   #   name       = azurerm_automation_runbook.aarplanepaldevneu01.name
#   #   runbook_id = azurerm_automation_runbook.aarplanepaldevneu01.id
#   #   parameters = {
#   #     param1 = "some-value"
#   #   }
#   # }
# }

/*resource "azurerm_storage_account" "stplanepaldevneu02" {
  name                     = "st${lower(var.app_name)}${var.environment}${var.location_abbreviation}02"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.st_account_tier
  account_replication_type = var.st_replication_type
}*/

resource "azurerm_storage_container" "scplanepaldevneu02" {
  name                  = "sc${lower(var.app_name)}${var.environment}${var.location_abbreviation}02"
  storage_account_name  = var.storage_account_name
  container_access_type = var.sc_container_access_type
}
