variable "resource_group_name" {
  description = "The name of the controller's RG"
  type        = string
  default     = "PAMonCloud-BYOI-Controller-RG"
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
}

variable "file_name" {
  description = "BYOI zip file name to be downloaded from Azure storage account"
  type        = string
}