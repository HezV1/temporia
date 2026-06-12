# ==============================================================================
# Temporia — AKS module outputs
# Credential outputs are marked sensitive so they never print to logs.
# ==============================================================================

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.magos_cluster.name
}

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.magos_cluster.id
}

output "kube_config" {
  description = "Raw kubeconfig for the cluster."
  value       = azurerm_kubernetes_cluster.magos_cluster.kube_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for the cluster admin user."
  value       = azurerm_kubernetes_cluster.magos_cluster.kube_config[0].client_certificate
  sensitive   = true
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster's system-assigned identity (used for AcrPull binding)."
  value       = azurerm_kubernetes_cluster.magos_cluster.identity[0].principal_id
}
