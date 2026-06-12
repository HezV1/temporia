# ==============================================================================
# Temporia — ACR module
# temperiaforge: the container registry. AcrPull is bound to the AKS identity
# so the cluster can pull images without an admin user or stored credentials.
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

resource "azurerm_container_registry" "temporia_forge" {
  name                = "temperiaforge"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"

  # admin_enabled is deliberately false: the cluster pulls via its managed
  # identity (AcrPull below), not via a shared admin username/password.
  admin_enabled = false

  tags = merge(var.tags, {
    Project   = "temporia"
    ManagedBy = "terraform"
  })
}

# Grant the AKS cluster identity permission to pull images from this registry.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.temporia_forge.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.aks_principal_id
  skip_service_principal_aad_check = true
}
