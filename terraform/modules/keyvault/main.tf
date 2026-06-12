# ==============================================================================
# Temporia — Key Vault module
# temporia-sanctum: the inner sanctum where the forge's secrets are kept.
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

# Resolves the tenant and the identity Terraform is currently running as, so we
# can grant that identity an access policy without hardcoding object IDs.
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "temporia_sanctum" {
  name                = "temporia-sanctum"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7

  # purge_protection is disabled for the free-tier lab so vaults can be fully
  # destroyed and recreated during teardown/rebuild cycles. Enable in prod.
  purge_protection_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  tags = merge(var.tags, {
    Project   = "temporia"
    ManagedBy = "terraform"
  })
}

# Give the deploying identity room to manage secrets and keys in the sanctum.
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.temporia_sanctum.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover",
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Purge",
    "Recover",
  ]
}
