# ==============================================================================
# Temporia — ACR module variables
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds the registry."
}

variable "location" {
  type        = string
  description = "Azure region for the registry."
}

variable "aks_principal_id" {
  type        = string
  description = "Principal ID of the AKS cluster identity to grant AcrPull."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)."
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto the registry's tags."
  default     = {}
}
