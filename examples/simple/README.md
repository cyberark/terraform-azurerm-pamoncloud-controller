# PAMonCloud Controller deployment example

Configuration in this directory creates a controller host to allow you to run the PAMonCloud solution with no further required prerequisites.

## Usage

To run this example you need input the required variables, then execute:

```bash
terraform init
terraform plan
terraform apply
```

Note that this example creates resources which can cost money (Azure VM, for example). Run `terraform destroy` when you don't need these resources.

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_pamoncloud_controller"></a> [pamoncloud_controller](/) | ../../ | n/a |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR block allowed for SSH inbound access | `string` | `"0.0.0.0/0"` |
| <a name="input_vm_admin_password"></a> [vm\_admin\_password](#input\_vm\_admin\_password) | Password for VM administrator user | `string` | n/a |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Resource ID of the storage account containing the BYOI zip | `string` | n/a |
| <a name="input_container_name"></a> [container\_name](#input\_container\_name) | Name of the storage account container with BYOI zip | `string` | n/a |
| <a name="input_file_name"></a> [file\_name](#input\_file\_name) | BYOI zip file name to be downloaded from Azure storage account | `string` | `"PAM_Self-Hosted_on_Azure.zip"` |

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