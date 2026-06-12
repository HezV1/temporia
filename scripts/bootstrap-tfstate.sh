#!/usr/bin/env bash
# ==============================================================================
# Temporia Security Lab — Terraform State Backend Bootstrap
# Usage: bash scripts/bootstrap-tfstate.sh [--dry-run]
#
# Creates the Azure storage that holds remote Terraform state. Run this ONCE,
# before the first `terraform init`, since the backend in backend.tf references
# resources that must already exist.
#
# Creates:
#   resource group  temporia-tfstate-rg
#   storage account temperiatfstate (must be globally unique — change if taken)
#   blob container  tfstate
# ==============================================================================
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[$(date '+%H:%M:%S')] $*"; }
run() { if $DRY_RUN; then echo "[DRY-RUN] $*"; else eval "$*"; fi; }

RG="temporia-tfstate-rg"
SA="temperiatfstate"
CONTAINER="tfstate"
LOCATION="${LOCATION:-eastus}"

log "=== Temporia tfstate backend bootstrap ==="

if ! command -v az &>/dev/null; then
  log "ERROR: az CLI not found. Run scripts/bootstrap.sh first."
  exit 1
fi

if ! az account show &>/dev/null; then
  log "ERROR: not logged in to Azure. Run: az login"
  exit 1
fi

log "Creating resource group $RG in $LOCATION..."
run "az group create --name '$RG' --location '$LOCATION' --output none"

log "Creating storage account $SA..."
run "az storage account create \
  --name '$SA' \
  --resource-group '$RG' \
  --location '$LOCATION' \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none"

log "Creating blob container $CONTAINER..."
run "az storage container create \
  --name '$CONTAINER' \
  --account-name '$SA' \
  --auth-mode login \
  --output none"

log ""
log "=== Backend ready ==="
log "Now run: cd terraform/environments/dev && terraform init"
