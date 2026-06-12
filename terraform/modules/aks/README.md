# AKS Module — `magos-cluster`

Provisions the Kubernetes cluster that runs the forge's workloads.

## What it creates

| Resource | Name | Notes |
|----------|------|-------|
| AKS cluster | `magos-cluster` | dns_prefix `temporia`, system-assigned identity |
| Node pool | `forgepool` | `var.node_count` × `var.node_vm_size`, 30 GB OS disk |

## Networking

- **Plugin:** Azure CNI (`network_plugin = "azure"`) — pods receive VNet IPs and are subject to NSG rules.
- **Service CIDR:** `10.1.0.0/16` (deliberately off the `10.0.0.0/16` VNet range).
- **DNS service IP:** `10.1.0.10`.

## Identity

The cluster uses a **system-assigned managed identity**. Its `principal_id` is exported so the ACR module can grant it `AcrPull` without storing any registry credentials.

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | — | Required |
| `location` | string | — | Required |
| `subnet_id` | string | — | `magos-cluster-subnet` ID |
| `node_count` | number | `1` | Keep low for cost control |
| `node_vm_size` | string | `Standard_B2s` | Cheap burstable default |
| `environment` | string | `dev` | Tag |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`cluster_name`, `cluster_id`, `kube_config` (sensitive), `client_certificate` (sensitive), `cluster_identity_principal_id`.

## Cost note

The node pool is the lab's main recurring cost. Destroy it via `scripts/teardown.sh` when not researching.
