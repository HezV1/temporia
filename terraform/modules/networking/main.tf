# ==============================================================================
# Temporia — Networking module
# VNet, subnets, and the omnissiah-gate NSG that wards the forge.
# ==============================================================================

# The forge needs a provider, but the module declares no hardcoded credentials
# or subscription — those come from the environment / az login.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

locals {
  # Common tags applied to every resource so cost and ownership are always
  # attributable. Module-specific tags merge on top of caller-provided tags.
  common_tags = merge(
    var.tags,
    {
      Project     = "temporia"
      ManagedBy   = "terraform"
      Environment = var.environment
      Owner       = var.owner
    }
  )
}

resource "azurerm_resource_group" "temporia" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "temporia_vnet" {
  name                = "temporia-vnet"
  resource_group_name = azurerm_resource_group.temporia.name
  location            = azurerm_resource_group.temporia.location
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

# Subnet that hosts the AKS node pool (the magos-cluster).
resource "azurerm_subnet" "magos_cluster" {
  name                 = "magos-cluster-subnet"
  resource_group_name  = azurerm_resource_group.temporia.name
  virtual_network_name = azurerm_virtual_network.temporia_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet reserved for supporting forge services (registries proxies, jump
# hosts, future Session-2 workloads).
resource "azurerm_subnet" "forge_services" {
  name                 = "forge-services-subnet"
  resource_group_name  = azurerm_resource_group.temporia.name
  virtual_network_name = azurerm_virtual_network.temporia_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# The omnissiah-gate: default-deny inbound, then explicit allows for HTTPS and
# the Kubernetes API. Source CIDR is configurable so it can be locked to a
# single operator IP in anything but throwaway dev.
resource "azurerm_network_security_group" "omnissiah_gate" {
  name                = "omnissiah-gate"
  resource_group_name = azurerm_resource_group.temporia.name
  location            = azurerm_resource_group.temporia.location
  tags                = local.common_tags

  # Lowest-priority catch-all: deny everything inbound. Higher-priority allow
  # rules below punch through this for the two ports we actually need.
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-kube-api"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }
}

# Bind the gate to the cluster subnet so node-facing traffic is filtered.
resource "azurerm_subnet_network_security_group_association" "magos_cluster" {
  subnet_id                 = azurerm_subnet.magos_cluster.id
  network_security_group_id = azurerm_network_security_group.omnissiah_gate.id
}
