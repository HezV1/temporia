# ==============================================================================
# Temporia — Monitoring module outputs
# ==============================================================================

output "workspace_id" {
  description = "Resource ID of the temporia-archive workspace."
  value       = azurerm_log_analytics_workspace.temporia_archive.id
}

output "workspace_name" {
  description = "Name of the temporia-archive workspace."
  value       = azurerm_log_analytics_workspace.temporia_archive.name
}

output "workspace_customer_id" {
  description = "Customer (workspace) ID used by agents to send data."
  value       = azurerm_log_analytics_workspace.temporia_archive.workspace_id
}
