locals {
  resource_group_name = "PAMonCloud-BYOI-Controller-RG"
  location            = "westeurope"
  vnet_cidr           = "10.0.0.0/16"
  subnet_cidr         = "10.0.1.0/24"
  vm_size             = "Standard_D2s_v3"
  vm_admin_user       = "azureadmin"
}

provider "azurerm" {
  features {}
}

################################################################################
# pamoncloud_controller Module
################################################################################
module "pamoncloud_controller" {
  source = "../../"

  resource_group_name = local.resource_group_name
  location            = local.location
  vnet_cidr           = local.vnet_cidr
  subnet_cidr         = local.subnet_cidr
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  vm_admin_user       = local.vm_admin_user
  vm_size             = local.vm_size
  storage_account_id  = var.storage_account_id
  container_name      = var.container_name
  file_name           = var.file_name
}