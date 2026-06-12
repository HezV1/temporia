# ==============================================================================
# Temporia — DEV remote backend
# State lives in an Azure storage account so it survives local machine loss and
# can be locked. Bootstrap the backend storage before first terraform init:
#   bash scripts/bootstrap-tfstate.sh
# ==============================================================================

terraform {
  backend "azurerm" {
    resource_group_name  = "temporia-tfstate-rg"
    storage_account_name = "temperiatfstate"
    container_name       = "tfstate"
    key                  = "temporia.dev.tfstate"
  }
}
