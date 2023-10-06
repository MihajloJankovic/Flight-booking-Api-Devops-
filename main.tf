terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.75"
    }
  }
  backend "azurerm" {
    resource_group_name  = "DevOps"
    storage_account_name = "stdevopsneu01"
    container_name       = "tfstate"
    key                  = "terraform-dev.tfstate"
    
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = false
      purge_soft_delete_on_destroy          = false
      recover_soft_deleted_key_vaults       = true
    }
  }
}

module "app_service" {
  source = "./modules/appservice"

  resource_group     = var.resource_group
  instrumentation_key     = module.logging.instrumentation_key
  location                = var.location
  app_name                = var.app_name
  environment             = var.environment
  dot_net_version         = var.dot_net_version
  app_sku                 = var.app_sku
  default_capacity        = var.app_service_default_capacity
  minimum                 = var.app_service_minimum
  maximum                 = var.app_service_maximum
  cpu_up_threshold        = var.cpu_up_threshold
  cpu_down_threshold      = var.cpu_down_threshold
  memory_up_threshold     = var.memory_up_threshold
  memory_down_threshold   = var.memory_down_threshold
  subneta_id              = module.network.appservice_subnet_id
  logging                 = module.logging.id
  endpoint_subnet_id      = module.network.subnet["subnet_app"].id
  location_abbreviation   = var.location_abbreviation
  app_destination_address = var.app_source_address
  levi9_public_ip         = var.levi9_public_ip
  vm_ip                 = module.vm.vm_ip
}

module "storage" {
  source = "./modules/storage"

  resource_group           = var.resource_group
  app_name                 = var.app_name
  account_tier             = var.account_tier
  replication_type         = var.replication_type
  location                 = var.location
  environment              = var.environment
  outbound_ip_address_list = module.app_service.outbound_ip_address_list
  subnet_id                = module.network.subnet["subnet_app_storage"].id
  levi9_public_ip          = var.levi9_public_ip
  vnet_id                  = module.network.vnet.id
  logging                  = module.logging.id
}

module "key_vault" {
  source = "./modules/keyvault"

  location                           = var.location
  resource_group                     = var.resource_group
  app_name                           = var.app_name
  environment                        = var.environment
  kv_app_sku_name                    = var.kv_app_sku_name
  tenant_id                          = module.app_service.tenant_id
  principal_id                       = module.app_service.object_id
  devops_kv_name                     = var.devops_kv_name
  key_sql_username                   = var.key_sql_username
  key_sql_password                   = var.key_sql_password
  app_secrets_keys                   = var.app_secrets_keys
  kv_base_URL_name                   = var.kv_base_URL_name
  kv_base_URL                        = var.kv_base_URL
  outbound_ip_address_list           = module.app_service.outbound_ip_address_list
  levi9_public_ip                    = var.levi9_public_ip
  subneta_id                         = module.network.subnet["subnet_app_keyvault"].id
  vnet_id                            = module.network.vnet.id
  logging                            = module.logging.id
  appservice_subnet_address_prefixes = module.network.appservice_subnet_address_prefixes
}

module "logging" {
  source = "./modules/logging"

  resource_group_name  = var.resource_group
  location             = var.location
  app_name             = var.app_name
  environment          = var.environment
  location_abbravation = var.location_abbreviation
  app_service_id       = module.app_service.web_app_id
  storage_account_id   = module.storage.account_id
  database_id          = module.sql.sqldb_id
  app_service_plan_id  = module.app_service.app_service_plan_id
  alerts_map           = var.alerts_map
  email_receiver       = var.email_receiver
}

module "sql" {
  source = "./modules/sql"

  resource_group        = var.resource_group
  app_name              = var.app_name
  environment           = var.environment
  location              = var.location
  location_abbreviation = var.location_abbreviation
  sql_version           = var.sql_version
  sqldb_sku_name        = var.sqldb_sku_name
  sqldb_sku_max_gb_size = var.sqldb_sku_max_gb_size
  sql_login             = module.key_vault.sql_username
  sql_password          = module.key_vault.sql_password
  app_source_address    = var.app_source_address
  subneta_id            = module.network.subnet["subnet_sql"].id
  vnet_id               = module.network.vnet.id
  logging               = module.logging.id

}

module "network" {
  source = "./modules/network"

  app_name                = var.app_name
  environment             = var.environment
  location                = var.location_abbreviation
  resource_group_name     = var.resource_group
  resource_group_location = var.location
  address_space           = var.address_space
  subnets                 = var.subnets
  location_abbreviation   = var.location_abbreviation
}

module "vm" {
  source = "./modules/vm"
  location                 = var.location
  resource_group           = var.resource_group  
  app_name                 = var.app_name
  environment              = var.environment 
  subneta_id               = module.network.subnet["subnet_vm"].id
  location_abbreviation    = var.location_abbreviation
  levi9_public_ip          = var.levi9_public_ip
  as_addr_prefixes         = module.network.appservice_subnet_address_prefixes
  vm_size                  = var.vm_size
}

# module "automation" {
#   source = "./modules/automation"

#   resource_group_name      = var.resource_group
#   app_name                 = var.app_name
#   environment              = var.environment
#   location                 = var.location
#   location_abbreviation    = var.location_abbreviation
#   aa_sku_name              = var.aa_sku_name
#   aar_runbook_type         = var.aar_runbook_type
#   aar_log_verbose          = var.aar_log_verbose
#   aar_log_progress         = var.aar_log_progress
#   aas_start_time           = var.aas_start_time
#   aas_timezone             = var.aas_timezone
#   st_account_tier          = var.stdb_account_tier
#   st_replication_type      = var.stdb_replication_type
#   sc_container_access_type = var.scdb_container_access_type
#   storage_account_name = module.storage.name
# }

