# ==============================================================================
# Temporia — Key Vault module variables
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds the vault."
}

variable "location" {
  type        = string
  description = "Azure region for the vault."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)."
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto the vault's tags."
  default     = {}
}
