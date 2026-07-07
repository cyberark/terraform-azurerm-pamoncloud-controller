# CyberArk PAMonCloud Controller

## Overview  
Welcome to the **CyberArk PAMonCloud Controller Terraform Module** repository! This project provides a tool to simplify the deployment of **PAMonCloud Controller node**, which includes everything you need in order to run PAMonCloud BYOI on **Azure**. It consists the required software installed, as well as permissions delegated to the VM using role assignments. The controller node is Ubuntu 22.04 based.

## Prerequisites  
Before using these modules, ensure you have the following:  
- **Terraform** installed  
- Azure account with necessary permissions for deploying resources  
- A valid **PAM_Self-Hosted_on_Azure.zip** file containing the BYOI solution  

Instructions for downloading the **PAM_Self-Hosted_on_Azure.zip** file can be found [here](https://docs.cyberark.com/pam-self-hosted/latest/en/content/pas%20cloud/images.htm#Createyourimages). It should be uploaded to an Azure Storage Account Container, the deployment will ask for the Storage Account and Container names in order to upload it to the controller.

## Usage

Below is an example usage of this Terraform module:

```hcl
module "pamoncloud_controller" {
  source = "cyberark/pamoncloud-controller/azurerm"

  resource_group_name = "ResourceGroupName"
  location            = "westeurope"
  vnet_cidr           = "172.31.0.0/16"
  subnet_cidr         = "172.31.1.0/24"
  allowed_ssh_cidr    = ["3.5.7.9/32"]
  vm_admin_user       = "azureadmin"
  vm_size             = "Standard_B2s"
  storage_account_id  = "/subscriptions/12345678-1234-5678-1234-567812345678/resourceGroups/PAM-Storage/providers/Microsoft.Storage/storageAccounts/storageaccountname"
  container_name      = "ContainerName"
  file_name           = "PAM_Self-Hosted_on_Azure.zip"
}
```

## Examples

See [`examples`](/examples) directory for working examples to reference.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](https://github.com/hashicorp/terraform) | >= 1.9.8, <= 1.13.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](https://github.com/hashicorp/terraform-provider-azurerm) | 3.116.0 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource Group name | `string` | `"PAMonCloud-BYOI-Controller-RG"` |
| <a name="input_location"></a> [location](#input\_location) | Location of the RG and VM | `string` | `"westeurope"` |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | CIDR block for the VNET | `string` | `"10.0.0.0/16"` |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | CIDR block for the subnet | `string` | `"10.0.1.0/24"` |
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | List of CIDR blocks allowed for SSH inbound access to the controller VM. Must NOT include 0.0.0.0/0 or ::/0. | `list(string)` | n/a |
| <a name="input_vm_admin_user"></a> [vm\_admin\_user](#input\_vm\_admin\_user) | Admin user for the VM | `string` | `"azureadmin"` |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | VM size for the controller | `string` | `"Standard_D2s_v3"` |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Resource ID of the storage account containing the BYOI zip | `string` | n/a |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the storage account container with BYOI zip | `string` | n/a |
| <a name="input_file_name"></a> [file\_name](#input\_file\_name) | BYOI zip file name to be downloaded from Azure storage account | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rg_name"></a> [rg\_name](#output\_rg\_name) | Controller's RG name. |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Controller's VM name. |
| <a name="output_vm_public_ip"></a> [vm\_public\_ip](#output\_vm\_public\_ip) | Controller's VM public IP. |

## Resources

### Retrieve information about a resource (post deployment)
You can use the `terraform state show` command followed by: `module.<module_name>.<resource_name>`  
Example: `terraform state show 'module.pamoncloud_controller.azurerm_virtual_machine.controller_vm:'`  
For list objects, you can use `terraform state list` to get all objects within the list.

#### **Virtual Machine**
| Resource                                | Description                                    |
|-----------------------------------------|------------------------------------------------|
| `azurerm_virtual_machine.controller_vm` | The virtual machine for the controller.        |

#### **User Assigned Identity**
| Resource                                                    | Description                                                                                                |
|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| `azurerm_user_assigned_identity.controller_identity`        | User-assigned managed identity attached to the controller VM.                                              |
| `azurerm_role_definition.controller_packer_builder`         | Custom role with the minimum actions required by Packer's azure-arm builder.                               |
| `azurerm_role_assignment.controller_packer_builder`         | Assigns the custom Packer-builder role to the controller identity at subscription scope.                   |
| `azurerm_role_assignment.controller_byoi_blob_reader`       | Grants `Storage Blob Data Reader` to the controller identity, scoped to the BYOI container only.           |

#### **Networking Resources**
| Resource                                                   | Description                                                 |
|------------------------------------------------------------|-------------------------------------------------------------|
| `azurerm_resource_group.controller_rg`                     | Resource group.                                             |
| `azurerm_virtual_network.controller_vnet`                  | Virtual network for the subnet.                             |
| `azurerm_network_security_group.controller_nsg`            | Network security group for the subnet.                      |
| `azurerm_network_interface.controller_network_interface`   | Network interface for the VM.                               |

<!-- END_TF_DOCS -->

## Permissions

The controller's user-assigned managed identity is granted only the privileges it actually needs:

1. **`Storage Blob Data Reader`** scoped to `<storage_account_id>/blobServices/default/containers/<container_name>` — the cloud-init script uses `az login --identity` and `az storage blob download` to fetch the BYOI zip from a single container; no other container in the same storage account is reachable, and no storage account keys are exposed.
2. **`PAMonCloud-Controller-PackerBuilder-<rg-name>`** — a module-defined custom Azure role assigned at subscription scope. It contains only the action set Packer's `azure-arm` builder issues for the BYOI image-build flow (Compute VM/disk/snapshot/image, Network NIC/NSG/PIP/VNet, Key Vault for the Windows-build temporary WinRM cert vault, Resources deployments, and resource-group create/read/delete for Packer's auto-created temp build RG). It deliberately does not grant `*`/`Contributor`, `Microsoft.Authorization/*`, `Microsoft.Compute/virtualMachines/runCommand/action`, `Microsoft.Storage/storageAccounts/listKeys/action`, `Microsoft.Compute/disks/beginGetAccess/action`, or other privileges unrelated to building images.

> **Subscription scope is required by current Packer behaviour.** Packer's `azure-arm` builder auto-creates a temporary build resource group (`pkr-Resource-Group-<id>`), which requires `Microsoft.Resources/subscriptions/resourceGroups/write` at subscription scope.

The `allowed_ssh_cidr` variable is required (no default) and validated to reject `0.0.0.0/0` / `::/0`, so SSH on port 22 is only ever opened to operator/jumpbox CIDRs that the deployer explicitly supplies.

## Software supply chain

The controller's first-boot tooling (Azure CLI and Packer) is installed by `cloud-init`'s native `apt:` module from the vendors' **signed apt repositories**, with the public signing keys embedded directly in [`files/cloud-init.yaml.tpl`](files/cloud-init.yaml.tpl). Every package is verified by `apt` against a signed `Release` file before installation.

| Package    | Source                                                       | Signing key fingerprint                                                          |
|------------|--------------------------------------------------------------|----------------------------------------------------------------------------------|
| `azure-cli`| `https://packages.microsoft.com/repos/azure-cli/ jammy main` | `BC52 8686 B50D 79E3 39D3  721C EB3E 94AD BE12 29CF` (Microsoft Release signing) |
| `packer`   | `https://apt.releases.hashicorp.com jammy main`              | `798A EC65 4E5C 1542 8C8E  42EE AA16 FCBC A621 E701` (HashiCorp Security)        |

Packer is pinned to version `1.13.1` (resolved as the apt package `packer=1.13.1-1`) in the `packages:` list of [`files/cloud-init.yaml.tpl`](files/cloud-init.yaml.tpl) and is then placed on `apt-mark hold` so unattended-upgrades cannot silently drift it. To bump Packer, edit that literal, confirm the new version exists at `https://apt.releases.hashicorp.com/dists/jammy/main/binary-amd64/Packages`, and re-apply.

> If either upstream signing key is rotated, refresh the corresponding `key:` block in [`files/cloud-init.yaml.tpl`](files/cloud-init.yaml.tpl) by re-fetching from `https://packages.microsoft.com/keys/microsoft.asc` or `https://apt.releases.hashicorp.com/gpg` and verifying the printed fingerprint against the vendor's published value before committing.

## Documentation  
- [Examples](/examples): Ready-to-use examples.  

## Licensing  
This repository is subject to the following licenses:  
- **Terraform templates**: Licensed under the Apache License, Version 2.0 ([LICENSE](https://github.com/cyberark/terraform-azure-pamoncloud-controller/blob/master/LICENSE)).  

## Contributing  
We welcome contributions! Please see our [Contributing Guidelines](https://github.com/cyberark/terraform-azure-pamoncloud-controller/blob/master/CONTRIBUTING.md) for more details.  

## About  
CyberArk is a global leader in **Identity Security**, providing powerful solutions for managing privileged access. Learn more at [www.cyberark.com](https://www.cyberark.com).  