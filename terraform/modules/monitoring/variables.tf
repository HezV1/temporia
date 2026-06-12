# ==============================================================================
# Temporia — Monitoring module variables
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds the workspace."
}

variable "location" {
  type        = string
  description = "Azure region for the workspace."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)."
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto the workspace's tags."
  default     = {}
}
