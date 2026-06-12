# Key Vault Module — `temporia-sanctum`

Provisions the secrets store for the forge.

## What it creates

| Resource | Name | Notes |
|----------|------|-------|
| Key Vault | `temporia-sanctum` | SKU `standard`, soft-delete 7d |
| Access policy | — | Get/List/Set/Delete/Purge/Recover for the deploying identity |

## Free-tier choices

- **`purge_protection_enabled = false`** — so the vault can be fully destroyed and recreated across teardown/rebuild cycles. **Enable in prod**, where accidental purge of secrets is a real risk.
- **`soft_delete_retention_days = 7`** — the minimum allowed, keeping recovery short for a throwaway lab.
- **`network_acls.default_action = "Allow"`** with `bypass = "AzureServices"` — open for lab convenience; tighten to selected networks in prod.

The deploying identity is resolved at apply time via `data.azurerm_client_config.current`, so the access policy binds to whoever runs `terraform apply` (you, after `az login`) without hardcoded object IDs.

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | — | Required |
| `location` | string | — | Required |
| `environment` | string | `dev` | Tag |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`key_vault_id`, `key_vault_name`, `key_vault_uri`.

## Note

Key Vault names are globally unique. If `temporia-sanctum` is taken, change it here and update the dev/prod outputs that reference it.
