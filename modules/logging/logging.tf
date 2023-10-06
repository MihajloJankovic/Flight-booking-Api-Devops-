variable "resource_group_name" {
  type        = string
  description = "DevOps"
}

variable "location" {
  type        = string
  description = "northeurope"
}

variable "app_name" {
  type        = string
  description = "PlanePal"
}

variable "environment" {
  type        = string
  description = "Abbravation for environment, used for defining name of resources"
}

variable "location_abbravation" {
  type        = string
  description = "Abbravation for resource group location, used for defining name of resources"
}

variable "app_service_id" {
  type        = string
  description = "App service id, used for creating service app alert"
}

variable "database_id" {
  type        = string
  description = "Database id, used for creating database alert"
}

variable "storage_account_id" {
  type        = string
  description = "Storage account id, used for creating storage account alert"
}

variable "app_service_plan_id" {
  type        = string
  description = "App service plan id, used for creating storage account alert"
}

variable "alerts_map" {
  type = map(object({
    name             = string
    message          = string
    metric_namespace = string
    metric_name      = string
    aggregation      = string
    operator         = string
    threshold        = number
  }))
}

variable "email_receiver" {
  type = map(object({
    name  = string
    email = string
  }))
}


data "azurerm_resource_group" "devops_rg" {
  name = var.resource_group_name
}

data "azurerm_subscription" "subscription" {}

resource "azurerm_log_analytics_workspace" "log-a-w" {
  name                = "log-${var.app_name}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "action_group" {
  name                = "ag-${var.app_name}-${var.environment}-${var.location}-01"
  resource_group_name = var.resource_group_name
  short_name          = "devops_ag"
  enabled             = true

  dynamic "email_receiver" {
    for_each = var.email_receiver

    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email
    }

  }
}

resource "azurerm_monitor_metric_alert" "alert_app_service" {
  for_each = var.alerts_map

  name                = each.value.name
  resource_group_name = var.resource_group_name
  scopes              = [each.key == "alert_app_service" ? var.app_service_id : each.key == "alert_storage_account" ? var.storage_account_id : var.database_id]
  description         = each.value.message

  criteria {
    metric_namespace = each.value.metric_namespace
    metric_name      = each.value.metric_name
    aggregation      = each.value.aggregation
    operator         = each.value.operator
    threshold        = each.value.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_monitor_activity_log_alert" "alert_serviceHealth" {
  name                = "ala-${var.app_name}-${var.environment}-${var.location}-01"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  scopes              = [data.azurerm_subscription.subscription.id]

  criteria {
    category = "ServiceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${var.app_name}-${var.environment}-${var.location}-01"
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
}