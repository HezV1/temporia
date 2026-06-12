# ==============================================================================
# Temporia — PROD root module
# Same module wiring as dev, with prod-appropriate defaults: locked-down CIDR,
# larger node pool. Key Vault purge-on-destroy is intentionally NOT enabled
# here so secrets cannot be accidentally lost.
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
  features {}
}

# --- Input variables for the prod environment ------------------------------

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds all prod resources."
  default     = "temporia-prod-rg"
}

variable "location" {
  type        = string
  description = "Azure region for the prod forge."
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Environment tag."
  default     = "prod"
}

variable "owner" {
  type        = string
  description = "Owner tag for all resources."
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed for HTTPS and kube-api access. MUST be locked down in prod."
}

variable "node_count" {
  type        = number
  description = "Number of forgepool nodes."
  default     = 2
}

variable "node_vm_size" {
  type        = string
  description = "VM size for forgepool nodes."
  default     = "Standard_D2s_v5"
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
  description = "Resource group holding the prod forge."
  value       = module.networking.resource_group_name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
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
