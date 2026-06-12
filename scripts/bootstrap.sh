#!/usr/bin/env bash
# ==============================================================================
# Temporia Security Lab — Bootstrap Script
# Usage: bash scripts/bootstrap.sh [--dry-run]
#
# Installs all required tooling on a fresh macOS ARM64 machine:
#   Homebrew, Azure CLI, Terraform, kubectl, Helm, k3d, gh, jq, shellcheck, trivy
#
# After running this script:
#   1. Run: az login
#   2. Run: cd terraform/environments/dev && terraform init && terraform apply
#   3. Run: az aks get-credentials --resource-group temporia-rg --name magos-cluster
# ==============================================================================
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[$(date '+%H:%M:%S')] $*"; }
run() { if $DRY_RUN; then echo "[DRY-RUN] $*"; else eval "$*"; fi; }
check() { command -v "$1" &>/dev/null; }

log "=== Temporia Bootstrap — The Omnissiah Wills It ==="
log "Mode: $(if $DRY_RUN; then echo DRY-RUN; else echo LIVE; fi)"

# --- Homebrew ---
if ! check brew; then
  log "Installing Homebrew..."
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  # Add to PATH for Apple Silicon
  run 'echo eval "$(/opt/homebrew/bin/brew shellenv)" >> ~/.zprofile'
  run 'eval "$(/opt/homebrew/bin/brew shellenv)"'
else
  log "Homebrew already installed: $(brew --version | head -1)"
fi

# --- Tools via Homebrew ---
# Format is "brew-package:command-to-check". The check command is what we test
# on PATH; the package is what we install if it's missing.
TOOLS=(
  "azure-cli:az"
  "terraform:terraform"
  "kubectl:kubectl"
  "helm:helm"
  "k3d:k3d"
  "gh:gh"
  "jq:jq"
  "shellcheck:shellcheck"
)

for entry in "${TOOLS[@]}"; do
  pkg="${entry%%:*}"
  cmd="${entry##*:}"
  if ! check "$cmd"; then
    log "Installing $pkg..."
    run "brew install $pkg"
  else
    log "$cmd already installed"
  fi
done

# --- OrbStack (Docker for Mac ARM64 — lighter than Docker Desktop) ---
if ! check docker; then
  log "Installing OrbStack (Docker runtime for macOS ARM64)..."
  run "brew install --cask orbstack"
else
  log "Docker runtime already present"
fi

# --- Trivy (container image scanner) ---
if ! check trivy; then
  log "Installing Trivy..."
  run "brew install aquasecurity/trivy/trivy"
else
  log "trivy already installed"
fi

# --- k3d local cluster for dev ---
# Skipped entirely in dry-run; in live mode it requires a running Docker daemon.
log "Verifying k3d can create a local cluster..."
if ! $DRY_RUN; then
  if ! check docker; then
    log "  ! docker not on PATH yet — open a new terminal, start OrbStack, then rerun to create the k3d cluster"
  elif ! docker info &>/dev/null; then
    log "  ! Docker daemon not running — start OrbStack, then rerun to create the k3d cluster"
  elif ! k3d cluster list 2>/dev/null | grep -q "temporia-dev"; then
    log "Creating local k3d dev cluster 'temporia-dev'..."
    k3d cluster create temporia-dev --servers 1 --agents 2 \
      --port "8080:80@loadbalancer" --port "8443:443@loadbalancer"
    log "Local dev cluster created. Switch context: kubectl config use-context k3d-temporia-dev"
  else
    log "k3d cluster 'temporia-dev' already exists"
  fi
fi

# --- Verify ---
log ""
log "=== Verification ==="
for cmd in brew az terraform kubectl helm k3d docker gh jq shellcheck trivy; do
  if check "$cmd"; then
    log "  ✓ $cmd"
  else
    log "  ✗ $cmd — NOT FOUND (may need new terminal for PATH)"
  fi
done

log ""
log "=== Next Steps ==="
log "  1. Open a new terminal (to pick up PATH changes)"
log "  2. az login"
log "  3. cd terraform/environments/dev"
log "  4. cp dev.tfvars.example dev.tfvars && vim dev.tfvars  # fill in your IP"
log "  5. terraform init"
log "  6. terraform plan -var-file=dev.tfvars"
log "  7. terraform apply -var-file=dev.tfvars"
log ""
log "The Omnissiah's tools are prepared. The Forge awaits."
