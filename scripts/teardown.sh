#!/usr/bin/env bash
# ==============================================================================
# Temporia Security Lab — Teardown Script
# Usage: bash scripts/teardown.sh [--confirm]
#
# Destroys all Azure resources to stop incurring costs.
# Preserves: GitHub repo, local k3d cluster, dashboard (Azure Static Web Apps free tier)
# ==============================================================================
set -euo pipefail

CONFIRM=false
[[ "${1:-}" == "--confirm" ]] && CONFIRM=true

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Temporia Teardown — Returning to the Warp ==="

if ! $CONFIRM; then
  echo ""
  echo "WARNING: This will destroy all Azure resources in temporia-rg."
  echo "The following will be DELETED: AKS cluster, VNet, NSGs, ACR, Key Vault"
  echo "The following will be PRESERVED: GitHub repo, dashboard (Static Web Apps free tier)"
  echo ""
  read -r -p "Type 'OMNISSIAH' to confirm destruction: " answer
  if [[ "$answer" != "OMNISSIAH" ]]; then
    log "Teardown cancelled."
    exit 0
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform/environments/dev"

if [[ ! -d "$TF_DIR" ]]; then
  log "ERROR: Terraform directory not found at $TF_DIR"
  exit 1
fi

log "Running terraform destroy in $TF_DIR..."
cd "$TF_DIR"

# Use dev.tfvars if present (it carries owner/allowed_cidr); fall back to the
# example so destroy still resolves required variables in CI/throwaway runs.
if [[ -f "dev.tfvars" ]]; then
  terraform destroy -auto-approve -var-file=dev.tfvars
else
  log "  ! dev.tfvars not found — using dev.tfvars.example for variable values"
  terraform destroy -auto-approve -var-file=dev.tfvars.example
fi

log ""
log "=== Teardown complete ==="
log "Azure resources destroyed. Credits preserved."
log "To rebuild: bash scripts/bootstrap.sh && terraform apply -var-file=dev.tfvars"
