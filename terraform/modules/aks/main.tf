# ==============================================================================
# Temporia — AKS module
# The magos-cluster: the Kubernetes cluster that runs the forge's workloads.
# ==============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

resource "azurerm_kubernetes_cluster" "magos_cluster" {
  name                = "magos-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "temporia"

  # System-assigned managed identity: the cluster gets its own Azure identity
  # so ACR pull (and future role assignments) can bind to it without secrets.
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name            = "forgepool"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    vnet_subnet_id  = var.subnet_id
    os_disk_size_gb = 30
  }

  # Azure CNI so pods get VNet IPs and NSG rules apply. Service CIDR is kept
  # off the VNet range (10.0.0.0/16) to avoid overlap.
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  tags = merge(var.tags, {
    Project   = "temporia"
    ManagedBy = "terraform"
  })
}
