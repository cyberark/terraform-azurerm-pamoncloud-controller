#### Set provider
provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}

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
    source_address_prefixes    = var.allowed_ssh_cidr
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

#### Create role definition + assignments
# Custom role: minimum actions required by Packer's azure-arm builder for the BYOI image-build flow. 
# Subscription-scope is necessary because Packer auto-creates its temporary build resource group.
resource "azurerm_role_definition" "controller_packer_builder" {
  name        = "PAMonCloud-Controller-PackerBuilder-${azurerm_resource_group.controller_rg.name}"
  scope       = data.azurerm_subscription.current.id
  description = "Minimum permissions for the PAMonCloud BYOI controller managed identity to run Packer's azure-arm builder."

  permissions {
    actions = [
      # Compute - VM lifecycle (capture/generalize used by Packer to convert VM to image)
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/generalize/action",
      "Microsoft.Compute/virtualMachines/capture/action",
      "Microsoft.Compute/virtualMachines/extensions/read",
      "Microsoft.Compute/virtualMachines/extensions/write",
      "Microsoft.Compute/virtualMachines/extensions/delete",
      "Microsoft.Compute/virtualMachines/vmSizes/read",
      # Compute - disks (OS + data disks per disk_additional_size)
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/delete",
      # Compute - snapshots (used when managed_image_*_snapshot_* vars are non-empty)
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/snapshots/write",
      "Microsoft.Compute/snapshots/delete",
      # Compute - managed images
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/delete",
      # Network - all artifacts the azure-arm builder provisions in the temp RG
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/delete",
      # KeyVault - REQUIRED for Windows component builds (vault, pvwa, cpm, psm)
      # Packer's azure-arm builder auto-provisions a temp Key Vault to deliver the WinRM cert
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/write",
      "Microsoft.KeyVault/vaults/delete",
      "Microsoft.KeyVault/vaults/deploy/action",
      "Microsoft.KeyVault/vaults/secrets/read",
      "Microsoft.KeyVault/vaults/secrets/write",
      "Microsoft.KeyVault/vaults/accessPolicies/write",
      # Resources - ARM deployment lifecycle (Packer drives provisioning via deployments)
      "Microsoft.Resources/deployments/read",
      "Microsoft.Resources/deployments/write",
      "Microsoft.Resources/deployments/delete",
      "Microsoft.Resources/deployments/cancel/action",
      "Microsoft.Resources/deployments/validate/action",
      "Microsoft.Resources/deployments/operationStatuses/read",
      # Resources - resource groups (auto-created temp RG for the build, image RG already exists)
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
    ]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.current.id]
}

resource "azurerm_role_assignment" "controller_packer_builder" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.controller_packer_builder.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.controller_identity.principal_id
}

resource "azurerm_role_assignment" "controller_blob_reader" {
  scope                = "${var.storage_account_id}/blobServices/default/containers/${var.container_name}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.controller_identity.principal_id
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

# Generate SSH key pair for VM authentication
resource "tls_private_key" "controller_vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key as a file
resource "local_file" "controller_vm_private_key" {
  content         = tls_private_key.controller_vm_ssh_key.private_key_pem
  filename        = "${path.cwd}/controller_vm_private_key.pem"
  file_permission = "0600"
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

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = tls_private_key.controller_vm_ssh_key.public_key_openssh
      path     = "/home/${var.vm_admin_user}/.ssh/authorized_keys"
    }
  }

  os_profile {
    computer_name  = "controller"
    admin_username = var.vm_admin_user

    # Run cloud-init script
    custom_data = base64encode(templatefile("${path.module}/files/cloud-init.yaml.tpl", {
      vm_admin_user        = var.vm_admin_user
      storage_account_name = regex("storageAccounts/([^/]+)", var.storage_account_id)[0]
      container_name       = var.container_name
      file_name            = var.file_name
    }))
  }

  tags = {
    Name = "PAMonCloud-BYOI-Controller"
  }

  depends_on = [
    azurerm_role_assignment.controller_packer_builder,
    azurerm_role_assignment.controller_blob_reader,
  ]
}