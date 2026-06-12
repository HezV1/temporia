# ==============================================================================
# Temporia — DEV root module
# Wires the five sub-modules into a single deployable forge.
# ==============================================================================

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Allows the sanctum vault to be fully purged on destroy so teardown is
      # clean and a later apply can recreate the same vault name.
      purge_soft_delete_on_destroy = true
    }
  }
}

# --- Input variables for the dev environment -------------------------------

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds all dev resources."
  default     = "temporia-rg"
}

variable "location" {
  type        = string
  description = "Azure region for the dev forge."
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Environment tag."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner tag for all resources."
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed for HTTPS and kube-api access. Set to YOUR_IP/32."
  default     = "0.0.0.0/0"
}

variable "node_count" {
  type        = number
  description = "Number of forgepool nodes."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for forgepool nodes."
  default     = "Standard_B2s"
}

# --- Modules ----------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  owner               = var.owner
  allowed_cidr        = var.allowed_cidr
}

module "aks" {
  source     = "../../modules/aks"
  depends_on = [module.networking]

  resource_group_name = module.networking.resource_group_name
  location            = var.location
  subnet_id           = module.networking.magos_cluster_subnet_id
  node_count          = var.node_count
  node_vm_size        = var.node_vm_size
  environment         = var.environment
}

module "acr" {
  source     = "../../modules/acr"
  depends_on = [module.aks]

  resource_group_name = module.networking.resource_group_name
  location            = var.location
  aks_principal_id    = module.aks.cluster_identity_principal_id
  environment         = var.environment
}

module "keyvault" {
  source     = "../../modules/keyvault"
  depends_on = [module.networking]

  resource_group_name = module.networking.resource_group_name
  location            = var.location
  environment         = var.environment
}

module "monitoring" {
  source     = "../../modules/monitoring"
  depends_on = [module.networking]

  resource_group_name = module.networking.resource_group_name
  location            = var.location
  environment         = var.environment
}

# --- Outputs ----------------------------------------------------------------

output "resource_group_name" {
  description = "Resource group holding the dev forge."
  value       = module.networking.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster — use with: az aks get-credentials."
  value       = module.aks.cluster_name
}

output "acr_name" {
  description = "Name of the container registry."
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "Login server for docker push/pull."
  value       = module.acr.acr_login_server
}

output "keyvault_uri" {
  description = "URI of the temporia-sanctum vault."
  value       = module.keyvault.key_vault_uri
}

output "log_analytics_workspace_name" {
  description = "Name of the temporia-archive workspace."
  value       = module.monitoring.workspace_name
}

output "dashboard_note" {
  description = "How to deploy the noosphere-dashboard."
  value       = "Deploy dashboard via: cd dashboard && az staticwebapp create --name noosphere-dashboard --resource-group ${var.resource_group_name} --source . --location ${var.location} --app-location src"
}
