output "rg_name" {
  value = resource.azurerm_resource_group.controller_rg.name
}

output "vm_name" {
  value = resource.azurerm_virtual_machine.controller_vm.name
}

output "vm_public_ip" {
  value = resource.azurerm_public_ip.controller_public_ip.ip_address
}