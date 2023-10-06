variable "environment" {
  type        = string
  description = "Name of Environment"
}

variable "resource_group" {
  type = string
}

variable "location" {
  type        = string
  description = "location where our resource needs provisioning in azure"
}

variable "app_name" {
  type        = string
  description = "Name of Application"
}

variable "subneta_id" {
  type = string
}

variable "location_abbreviation" {
  type = string
}
variable "levi9_public_ip" {
  type    = string
}
variable "as_addr_prefixes" {
    
}

variable "vm_size" {
    type = string
}

data "azurerm_key_vault" "devops-kv" {
  name                = "kv-devops-dev-neu-00"
  resource_group_name = var.resource_group
}

data "azurerm_key_vault_secret" "vm-admin-user" {
    name = "vm-admin-user"
    key_vault_id = data.azurerm_key_vault.devops-kv.id
}

data "azurerm_key_vault_secret" "vm-admin-pass" {
    name = "vm-admin-pass"
    key_vault_id = data.azurerm_key_vault.devops-kv.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-${var.environment}-00"
  location              = var.location
  resource_group_name   = var.resource_group
  network_interface_ids = [azurerm_network_interface.net_int.id]
  size                  = var.vm_size

  admin_username = data.azurerm_key_vault_secret.vm-admin-user.value
  admin_password = data.azurerm_key_vault_secret.vm-admin-pass.value

  os_disk {
    name                 = "OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "win10-21h2-ent"
    version   = "latest"
  }
 
}

resource "azurerm_network_interface" "net_int" {
  name                = "nic-${var.app_name}-${var.environment}-${var.location_abbreviation}-00"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     =  var.subneta_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm_ip.id
  }
}

resource "azurerm_public_ip" "vm_ip" {
  name                = "publicip-vm-${var.environment}-01"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-vm-${lower(var.app_name)}-${var.environment}-${var.location}-01"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = var.levi9_public_ip
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet_network_security_group_association" "vm_nsg_assoc" {
  subnet_id                 = var.subneta_id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}