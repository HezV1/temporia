# ==============================================================================
# Temporia — AKS module variables
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource group that holds the cluster."
}

variable "location" {
  type        = string
  description = "Azure region for the cluster."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet the node pool attaches to (magos-cluster-subnet)."
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the forgepool. Keep at 1 for cost-controlled dev."
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for forgepool nodes. Standard_B2s is the cheap burstable default."
  default     = "Standard_B2s"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)."
  default     = "dev"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto the cluster's tags."
  default     = {}
}
