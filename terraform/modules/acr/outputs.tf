# ==============================================================================
# Temporia — ACR module outputs
# ==============================================================================

output "acr_id" {
  description = "Resource ID of the temperiaforge registry."
  value       = azurerm_container_registry.temporia_forge.id
}

output "acr_name" {
  description = "Name of the temperiaforge registry."
  value       = azurerm_container_registry.temporia_forge.name
}

output "acr_login_server" {
  description = "Login server hostname for docker push/pull."
  value       = azurerm_container_registry.temporia_forge.login_server
}
