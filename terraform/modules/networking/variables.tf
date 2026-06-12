# ==============================================================================
# Temporia — Networking module variables
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that holds all Temporia networking."
}

variable "location" {
  type        = string
  description = "Azure region for the forge."
  default     = "eastus"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner tag applied to all resources."
  default     = "temporia"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed for HTTPS and kube-api access — set to your IP in production."
  default     = "0.0.0.0/0"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto the module's common tags."
  default     = {}
}
