# ==============================================================================
# Temporia — Monitoring module
# temporia-archive: the Lexmechanic's data-vault — a Log Analytics workspace
# that collects logs and telemetry for the purple-team detection loop.
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

resource "azurerm_log_analytics_workspace" "temporia_archive" {
  name                = "temporia-archive"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"

  # 30-day retention keeps lab costs bounded while still giving detection
  # engineering a useful window of history.
  retention_in_days = 30

  tags = merge(var.tags, {
    Project   = "temporia"
    ManagedBy = "terraform"
  })
}
