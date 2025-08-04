variable "resource_group_name" {
  description = "The name of the controller's RG"
  type        = string
  default     = "PAMonCloud-BYOI-Controller-RG"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_.()]{1,89}$", var.resource_group_name))
    error_message = <<-EOF
      The resource group name must meet the following requirements:
        - Be between 1 and 90 characters long.
        - Start with a letter
        - Contain only alphanumeric characters, underscores (_), hyphens (-), or parentheses (()).
    EOF
  }
}

variable "location" {
  description = "Location for deployment"
  type        = string
  default     = "westeurope"
}

variable "vnet_cidr" {
  description = "VNET CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH inbound access"
  type        = string
  default     = "0.0.0.0/0" # Change CIDR scope for better security
}

variable "vm_admin_user" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
  validation {
    condition = (
      can(regex("^[a-zA-Z0-9_.-]{1,20}$", var.vm_admin_user)) &&
      !can(regex("^(Administrator|Guest|DefaultAccount|System)$", var.vm_admin_user))
    )
    error_message = <<-EOF
      The admin username must meet the following requirements:
        - Be between 1 and 20 characters long.
        - Contain only alphanumeric characters, underscores (_), hyphens (-), or periods (.).
        - Must not contain disallowed characters: \ / [ ] : ; | = , + * ? < > @ "
        - Cannot use reserved usernames such as Administrator, Guest, DefaultAccount, or System.
    EOF
  }
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "storage_account_id" {
  description = "Resource ID of the storage account containing the BYOI zip"
  type        = string
  validation {
    condition = can(
      regex("^/subscriptions/[0-9a-fA-F-]{36}/resourceGroups/[a-zA-Z0-9_.-]+/providers/Microsoft.Storage/storageAccounts/[a-z][a-z0-9]{2,23}$", var.storage_account_id)
    )
    error_message = <<-EOF
      The storage_account_id must be a valid Azure storage account resource ID in the following format:
      /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/storageAccounts/{storageAccountName}
    EOF
  }
}

variable "container_name" {
  description = "Name of the storage account container where BYOI zip is stored"
  type        = string
  validation {
    condition     = can(regex("^.{3,36}$", var.container_name))
    error_message = "Must be 3 to 63 characters long."
  }
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.container_name))
    error_message = "Contain only lowercase letters (a-z), numbers (0-9), and hyphens (-)"
  }
  validation {
    condition     = can(regex("^[a-z0-9]", var.container_name))
    error_message = "Start with a lowercase letter or number."
  }
  validation {
    condition     = can(regex("[a-z0-9]$", var.container_name))
    error_message = "Must not end with a hyphen."
  }
}

variable "file_name" {
  description = "BYOI zip file name to be downloaded from Azure storage account"
  type        = string
}