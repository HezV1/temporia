# ==============================================================================
# Temporia — Key Vault module outputs
# ==============================================================================

output "key_vault_id" {
  description = "Resource ID of the temporia-sanctum vault."
  value       = azurerm_key_vault.temporia_sanctum.id
}

output "key_vault_name" {
  description = "Name of the temporia-sanctum vault."
  value       = azurerm_key_vault.temporia_sanctum.name
}

output "key_vault_uri" {
  description = "URI of the temporia-sanctum vault."
  value       = azurerm_key_vault.temporia_sanctum.vault_uri
}
