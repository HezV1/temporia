# ACR Module — `temperiaforge`

Provisions the container registry and binds it to the cluster identity.

## What it creates

| Resource | Name | Notes |
|----------|------|-------|
| Container registry | `temperiaforge` | SKU `Basic`, `admin_enabled = false` |
| Role assignment | — | `AcrPull` for the AKS identity on this registry |

## Why no admin user

`admin_enabled = false` is intentional. A shared admin username/password is a credential to leak. Instead the AKS cluster's system-assigned managed identity is granted `AcrPull`, so image pulls are identity-bound and secretless.

This module depends on the AKS module's `cluster_identity_principal_id` output, passed in as `var.aks_principal_id`.

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | — | Required |
| `location` | string | — | Required |
| `aks_principal_id` | string | — | AKS identity principal ID |
| `environment` | string | `dev` | Tag |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`acr_id`, `acr_name`, `acr_login_server`.

## Note

ACR registry names must be globally unique and alphanumeric. `temperiaforge` is the project's chosen name; if it collides on first apply, change it here and in the dev/prod root outputs.
