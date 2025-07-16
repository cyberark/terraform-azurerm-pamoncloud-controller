variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH inbound access"
  type        = string
  default     = "0.0.0.0/0" # Change CIDR scope for better security
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
  default     = "PAM_Self-Hosted_on_Azure.zip"
}