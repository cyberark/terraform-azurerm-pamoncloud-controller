#### Set provider
provider "azurerm" {
  features {}
}

#### Create RG and related objects
resource "azurerm_resource_group" "controller_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_network_security_group" "controller_nsg" {
  name                = "PAMonCloud-BYOI-Controller-NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.controller_rg.name

  security_rule {
    name                       = "InboundSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.controller_rg]
}

resource "azurerm_virtual_network" "controller_vnet" {
  name                = "PAMonCloud-BYOI-Controller-VNet"
  location            = azurerm_resource_group.controller_rg.location
  resource_group_name = azurerm_resource_group.controller_rg.name
  address_space       = [var.vnet_cidr]

  subnet {
    name           = "Controller-Subnet"
    address_prefix = var.subnet_cidr
    security_group = azurerm_network_security_group.controller_nsg.id
  }

  tags = {
    Name = "PAMonCloud-BYOI-Controller-VNet"
  }
}

#### Create user-assigned managed identity
resource "azurerm_user_assigned_identity" "controller_identity" {
  name                = "Controller-Identity"
  resource_group_name = azurerm_resource_group.controller_rg.name
  location            = azurerm_resource_group.controller_rg.location
}

#### Create role assignment
resource "azurerm_role_assignment" "storage_account_role_assignment" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.controller_identity.principal_id

  depends_on = [resource.azurerm_user_assigned_identity.controller_identity]
}

#### Create VM resources
resource "azurerm_public_ip" "controller_public_ip" {
  name                = "PAMonCloud-BYOI-Controller-Public-IP"
  resource_group_name = azurerm_resource_group.controller_rg.name
  location            = azurerm_resource_group.controller_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "controller_network_interface" {
  name                = "Controller-Network-Interface"
  location            = var.location
  resource_group_name = azurerm_resource_group.controller_rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = (resource.azurerm_virtual_network.controller_vnet.subnet[*].id)[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.controller_public_ip.id
  }

  depends_on = [resource.azurerm_public_ip.controller_public_ip]
}

resource "azurerm_virtual_machine" "controller_vm" {
  name                          = "PAMonCloudController"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.controller_rg.name
  network_interface_ids         = [azurerm_network_interface.controller_network_interface.id]
  vm_size                       = var.vm_size
  delete_os_disk_on_termination = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controller_identity.id]
  }

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "controller-osdisk"
    os_type           = "Linux"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "controller"
    admin_username = var.vm_admin_user
    admin_password = var.vm_admin_password

    # Run cloud-init script
    custom_data = base64encode(templatefile("${path.module}/files/cloud-init.yaml.tpl", {
      vm_admin_user        = var.vm_admin_user
      storage_account_name = regex("storageAccounts/([^/]+)", var.storage_account_id)[0]
      container_name       = var.container_name
      file_name            = var.file_name
    }))
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Name = "PAMonCloud-BYOI-Controller"
  }

  depends_on = [resource.azurerm_role_assignment.storage_account_role_assignment]
}