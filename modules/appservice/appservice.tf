variable "resource_group" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "app_name" {
  type = string
}

variable "instrumentation_key" {
  type = string
}

variable "dot_net_version" {
  type = string
}

variable "app_sku" {
  type = string
}

variable "subneta_id" {
  type = string
}

variable "endpoint_subnet_id" {
  type = string
}

variable "minimum" {
  type = number
}

variable "maximum" {
  type = number
}

variable "default_capacity" {
  type = number
}

variable "cpu_up_threshold" {

}

variable "cpu_down_threshold" {

}

variable "memory_up_threshold" {

}

variable "memory_down_threshold" {

}

variable "logging" {
  type = string
}

variable "vm_ip" {
  type = string
}
variable "location_abbreviation" {
  type = string
}

variable "app_destination_address" {
  type = string
}

variable "levi9_public_ip" {
  type = string
}


resource "azurerm_service_plan" "service-plan-planepal-dev-neu-00" {
  name                = "asp-${var.app_name}-${var.environment}-${var.location}-00"
  resource_group_name = var.resource_group
  location            = var.location
  sku_name            = var.app_sku
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "app-PlanePal-dev-northeurope-00" {
  name                      = "app-${var.app_name}-${var.environment}-${var.location}-00"
  resource_group_name       = var.resource_group
  location                  = var.location
  service_plan_id           = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
  virtual_network_subnet_id = var.subneta_id

  site_config {
    always_on = "false"
  }
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    "dotnet_framework_version"               = "${var.dot_net_version}"
    "ApplicationInsights:InstrumentationKey" = "${var.instrumentation_key}"
  }
}

data "azurerm_monitor_diagnostic_categories" "asp_cat" {
  resource_id = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
}

resource "azurerm_monitor_diagnostic_setting" "asp_diag" {
  name                       = "app_service_plan-diag"
  target_resource_id         = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
  log_analytics_workspace_id = var.logging

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.asp_cat.logs

    content {
      category = log.value
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.asp_cat.metrics

    content {
      category = metric.value
    }
  }
}

resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-app-${lower(var.app_name)}-${var.environment}-${var.location_abbreviation}-01"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "allow-vm"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 200
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_ranges    = [443]
    source_address_prefix      = var.vm_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-levi9"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = 100
    direction                  = "Inbound"
    source_port_range          = "*"
    destination_port_range     = 443
    source_address_prefix      = var.levi9_public_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association_for_app" {
  subnet_id                 = var.subneta_id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

# resource "azurerm_monitor_autoscale_setting" "scale_action_setting" {
#   name                = "app-scale-${var.app_name}-${var.environment}-${var.location}-00"
#   resource_group_name = var.resource_group
#   location            = var.location
#   target_resource_id  = azurerm_windows_web_app.app-PlanePal-dev-northeurope-00.id

#   profile {
#     name = "defaultProfile"

#     capacity {
#       default = var.default_capacity
#       minimum = var.minimum
#       maximum = var.maximum
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "CPU Time"
#         metric_resource_id = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT10M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = var.cpu_up_threshold
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Average memory working set"
#         metric_resource_id = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT15M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = var.memory_up_threshold
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }
#     rule {
#       metric_trigger {
#         metric_name        = "Average memory working set"
#         metric_resource_id = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT10M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = var.memory_down_threshold
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }
#     rule {
#       metric_trigger {
#         metric_name        = "CPU Time"
#         metric_resource_id = azurerm_service_plan.service-plan-planepal-dev-neu-00.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT10M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = var.cpu_down_threshold
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }
#   }

#   notification {
#     email {
#       send_to_subscription_administrator    = true
#       send_to_subscription_co_administrator = true
#     }
#   }
# }
