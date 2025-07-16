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
  allowed_ssh_cidr    = "3.5.7.9/32"
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
| <a name="requirement_terraform"></a> [terraform](https://github.com/hashicorp/terraform) | 1.9.8 |

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
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR block allowed for SSH inbound access | `string` | `"0.0.0.0/0"` |
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
| Resource                                                    | Description                                                 |
|-------------------------------------------------------------|-------------------------------------------------------------|
| `azurerm_user_assigned_identity.controller_identity`        | Identity to manage VM permissions.                          |
| `azurerm_role_assignment.storage_account_role_assignment`   | Assignment of the identity.                                 |

#### **Networking Resources**
| Resource                                                   | Description                                                 |
|------------------------------------------------------------|-------------------------------------------------------------|
| `azurerm_resource_group.controller_rg`                     | Resource group.                                             |
| `azurerm_virtual_network.controller_vnet`                  | Virtual network for the subnet.                             |
| `azurerm_network_security_group.controller_nsg`            | Network security group for the subnet.                      |
| `azurerm_network_interface.controller_network_interface`   | Network interface for the VM.                               |

<!-- END_TF_DOCS -->

## Documentation  
- [Examples](/examples): Ready-to-use examples.  

## Licensing  
This repository is subject to the following licenses:  
- **Terraform templates**: Licensed under the Apache License, Version 2.0 ([LICENSE](https://github.com/cyberark/terraform-azure-pamoncloud-controller/blob/master/LICENSE)).  

## Contributing  
We welcome contributions! Please see our [Contributing Guidelines](https://github.com/cyberark/terraform-azure-pamoncloud-controller/blob/master/CONTRIBUTING.md) for more details.  

## About  
CyberArk is a global leader in **Identity Security**, providing powerful solutions for managing privileged access. Learn more at [www.cyberark.com](https://www.cyberark.com).  