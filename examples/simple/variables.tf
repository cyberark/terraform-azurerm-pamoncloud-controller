variable "allowed_ssh_cidr" {
  description = "List of CIDR blocks allowed for SSH inbound access to the controller VM. Must NOT include 0.0.0.0/0 or ::/0."
  type        = list(string)

  validation {
    condition     = length(var.allowed_ssh_cidr) > 0
    error_message = "At least one CIDR must be supplied."
  }
  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr : can(cidrnetmask(cidr))])
    error_message = "Every entry must be a valid IPv4 CIDR (e.g. X.X.X.X/32)."
  }
  validation {
    condition     = !contains(var.allowed_ssh_cidr, "0.0.0.0/0") && !contains(var.allowed_ssh_cidr, "::/0")
    error_message = "Refusing to open SSH to the world: 0.0.0.0/0 / ::/0 are not allowed. Specify operator/jumpbox CIDR(s)."
  }
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