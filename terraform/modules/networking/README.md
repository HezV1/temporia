# Networking Module — `omnissiah-gate`

Provisions the foundational network for the Temporia forge: the resource group, the VNet, two subnets, and the warded NSG.

## What it creates

| Resource | Name | Notes |
|----------|------|-------|
| Resource group | `var.resource_group_name` | Holds every Temporia resource |
| Virtual network | `temporia-vnet` | `10.0.0.0/16` |
| Subnet | `magos-cluster-subnet` | `10.0.1.0/24` — AKS node pool |
| Subnet | `forge-services-subnet` | `10.0.2.0/24` — supporting services |
| Network security group | `omnissiah-gate` | Default-deny inbound + HTTPS/API allows |
| NSG association | — | Binds the gate to the cluster subnet |

## The omnissiah-gate rules

1. **deny-all-inbound** (priority 4096) — catch-all deny.
2. **allow-https-inbound** (priority 100) — TCP 443 from `var.allowed_cidr`.
3. **allow-kube-api** (priority 110) — TCP 6443 from `var.allowed_cidr`.

> **Lock it down.** `var.allowed_cidr` defaults to `0.0.0.0/0` for first-run convenience. Set it to `YOUR_IP/32` (`curl ifconfig.me`) in `dev.tfvars` so the kube-API isn't exposed to the internet.

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | — | Required |
| `location` | string | `eastus` | Azure region |
| `environment` | string | `dev` | Tag |
| `owner` | string | `temporia` | Tag |
| `allowed_cidr` | string | `0.0.0.0/0` | Source CIDR for 443/6443 |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`resource_group_name`, `vnet_id`, `vnet_name`, `magos_cluster_subnet_id`, `forge_services_subnet_id`, `nsg_id`.
