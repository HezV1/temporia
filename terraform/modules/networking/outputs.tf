# ==============================================================================
# Temporia — Networking module outputs
# ==============================================================================

output "resource_group_name" {
  description = "Name of the Temporia resource group."
  value       = azurerm_resource_group.temporia.name
}

output "vnet_id" {
  description = "ID of the temporia-vnet."
  value       = azurerm_virtual_network.temporia_vnet.id
}

output "vnet_name" {
  description = "Name of the temporia-vnet."
  value       = azurerm_virtual_network.temporia_vnet.name
}

output "magos_cluster_subnet_id" {
  description = "ID of the subnet that hosts the AKS node pool."
  value       = azurerm_subnet.magos_cluster.id
}

output "forge_services_subnet_id" {
  description = "ID of the supporting forge-services subnet."
  value       = azurerm_subnet.forge_services.id
}

output "nsg_id" {
  description = "ID of the omnissiah-gate network security group."
  value       = azurerm_network_security_group.omnissiah_gate.id
}
