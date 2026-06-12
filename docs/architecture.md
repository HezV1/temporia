# Temporia — Architecture Document

> A Dark Mechanicum-aligned purple team security research lab deployed on Azure Kubernetes Service.

---

## Overview

Temporia is a hybrid local + cloud security lab built to showcase Kubernetes, Helm, Terraform, Azure networking, Bash scripting, and full-stack security tooling (offensive + defensive). The core principle: **everything is code**. Infrastructure, cluster configuration, and security tooling are all provisioned declaratively with zero manual steps beyond authentication.

---

## Design Principles

1. **40k flavor is structural, not cosmetic.** Namespace names (skitarii, myrmidon, omnissiah-system) map to real security roles. The lore is mnemonics, not decoration.
2. **On-demand AKS.** The cluster costs money per hour. `terraform apply` brings it up for a session; `teardown.sh` destroys it. The dashboard and ACR are always-on because they're free tier.
3. **Everything as code.** Terraform owns the cloud. Helm owns the cluster. CI validates both on every push. No manual click-ops.
4. **Default deny, allowlist up.** NSG denies all inbound by default; specific ports are explicitly opened. Calico NetworkPolicies default-deny per namespace. Defense in depth at every layer.
5. **Purple team loop.** The lab is not a CTF range — it's a real pipeline: attack-sim.sh fires an attack, Wazuh and Falco detect it, the alert surfaces in Wazuh's dashboard. Every attack has a detector.
6. **Free tier first.** Azure free trial ($200 credit) is the budget. B2s nodes, Basic ACR, Log Analytics 30-day retention. No Sentinel.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure (temporia-rg)                      │
│                                                                   │
│  ┌───────────────────── temporia-vnet (10.0.0.0/16) ───────────┐ │
│  │                                                               │ │
│  │  magos-cluster-subnet   10.0.1.0/24                         │ │
│  │  ┌───────────────────────────────────────────────────────┐   │ │
│  │  │  AKS: magos-cluster (B2s nodes, SystemAssigned ID)    │   │ │
│  │  │                                                        │   │ │
│  │  │  ┌─────────────────┐  ┌──────────────────────────┐    │   │ │
│  │  │  │ omnissiah-system │  │       skitarii           │    │   │ │
│  │  │  │ cert-manager     │  │  Wazuh SIEM + Falco      │    │   │ │
│  │  │  │ nginx-ingress    │  │  runtime security        │    │   │ │
│  │  │  └─────────────────┘  └──────────────────────────┘    │   │ │
│  │  │                                                        │   │ │
│  │  │  ┌─────────────────┐  ┌──────────────────────────┐    │   │ │
│  │  │  │    myrmidon     │  │      lexmechanic         │    │   │ │
│  │  │  │  attack tools   │  │  log aggregation         │    │   │ │
│  │  │  │  target pods    │  │  threat intel            │    │   │ │
│  │  │  └─────────────────┘  └──────────────────────────┘    │   │ │
│  │  │                                                        │   │ │
│  │  │  ┌─────────────────┐                                  │   │ │
│  │  │  │    cogitator    │                                   │   │ │
│  │  │  │  AI analysis    │                                   │   │ │
│  │  │  └─────────────────┘                                  │   │ │
│  │  └───────────────────────────────────────────────────────┘   │ │
│  │                                                               │ │
│  │  forge-services-subnet  10.0.2.0/24                         │ │
│  │  NSG: omnissiah-gate — deny-all-inbound (priority 4096)     │ │
│  │       allow HTTPS 443 from allowed_cidr (priority 100)       │ │
│  │       allow kube-api 6443 from allowed_cidr (priority 110)   │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ACR: temperiaforge (Basic, AcrPull granted to AKS identity)    │
│  Key Vault: temporia-sanctum (soft-delete 7d, no purge protect) │
│  Log Analytics: temporia-archive (30d retention, PerGB2018)     │
│  Static Web App: noosphere-dashboard (free tier, always-on)     │
└─────────────────────────────────────────────────────────────────┘
                    ↕  kubectl / Terraform / Helm / bash
┌─────────────────────────────────────────────────────────────────┐
│              Local Dev — Mac M3 Ultra (128GB RAM, ARM64)         │
│                                                                   │
│  OrbStack (Docker runtime)                                        │
│  k3d: temporia-dev cluster (mirrors AKS config locally)          │
│  Tools: az, terraform, kubectl, helm, gh, jq, trivy, shellcheck  │
│  Kali tools installed into myrmidon pods or local containers     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### Terraform Modules

| Module | Resources Created | Purpose |
|--------|-----------------|---------|
| `networking` | VNet, 2 subnets, NSG + associations | Network foundation |
| `aks` | AKS cluster, node pool | Compute |
| `acr` | Container registry + AcrPull role assignment | Image storage |
| `keyvault` | Key Vault | Secrets at rest |
| `monitoring` | Log Analytics workspace | Observability sink |

All modules share tags: `Project=temporia`, `ManagedBy=terraform`.

### Helm Chart: temporia-stack

The umbrella chart configures the cluster's baseline security posture — it does not deploy application workloads.

| Template | What it does |
|----------|-------------|
| `namespaces.yaml` | Creates 5 namespaces with 40k lore labels |
| `network-policies.yaml` | Default-deny ingress + egress per workload namespace; allow-dns-egress |
| `resource-quotas.yaml` | CPU/memory ceilings for skitarii (2cpu/4Gi) and myrmidon (1cpu/2Gi) |
| `rbac.yaml` | ClusterRole `temporia-read-only` + RoleBindings to `temporia-viewers` group |

### Namespace Taxonomy

| Namespace | 40k Role | Security Role |
|-----------|----------|--------------|
| `omnissiah-system` | Tech-Priesthood | Platform (ingress, cert-manager, cluster services) |
| `skitarii` | Warrior-Cyborgs | Defense (Wazuh, Falco) |
| `myrmidon` | Heavy Combat Units | Offense (attack tools, target pods) |
| `lexmechanic` | Data-Archivists | Logging + threat intelligence |
| `cogitator` | Machine Spirit | AI-assisted analysis |

### Security Stack

**Defense layer (skitarii namespace):**
- **Wazuh SIEM** — log ingestion, rule-based alerting, FIM
- **Falco** — syscall-level runtime security; detects privilege escalation, container escapes, unusual network activity
- **Calico NetworkPolicies** — default-deny between namespaces; explicit allow rules per workload

**Offense layer (myrmidon namespace):**
- `attack-sim.sh` — scripted attack scenarios (port scans, bruteforce attempts, PoC runs)
- Target containers — intentionally vulnerable workloads (e.g., Metasploitable3-class images)
- Red team tooling installed into myrmidon pods via ACR images

**Purple team loop:**
```
attack-sim.sh fires event
       ↓
syscalls / network logs captured by Falco / Wazuh agent
       ↓
Alert generated in Wazuh dashboard (≤60s SLA)
       ↓
ISC-verified: attack → detect → alert pipeline functional
```

### CI Pipeline (.github/workflows/ci.yml)

Three parallel jobs on every push to `main`:

1. **terraform-validate** — `terraform fmt -check` + `terraform validate` with `-backend=false`
2. **helm-lint** — `helm lint` + `helm template` on temporia-stack
3. **shellcheck** — static analysis on all scripts in `./scripts/` at `severity: error`

### Dashboard (Azure Static Web Apps — free tier)

A pure static site at `dashboard/src/`. Always online regardless of AKS state.

- Dark cyberpunk theme (#0a0a0f bg, #ff6b00 accent)
- Fetches `status.json` at runtime; shows cluster online/offline badge
- Graceful "Lab Offline" state for when AKS is torn down (normal operating mode between demos)
- CSP headers via `staticwebapp.config.json`

---

## Operational Workflows

### Spin Up

```bash
# 1. Verify tools (one-time: ./scripts/bootstrap.sh)
# 2. Authenticate
az login
az account set --subscription <SUBSCRIPTION_ID>

# 3. Provision state backend (one-time)
./scripts/bootstrap-tfstate.sh

# 4. Configure
cp terraform/environments/dev/dev.tfvars.example terraform/environments/dev/dev.tfvars
# edit allowed_cidr to your current IP

# 5. Provision Azure infra
cd terraform/environments/dev && terraform init && terraform apply

# 6. Get kubeconfig
az aks get-credentials --resource-group temporia-rg --name magos-cluster

# 7. Deploy baseline
helm upgrade --install temporia-stack helm/charts/temporia-stack --create-namespace

# 8. Verify
kubectl get namespaces
kubectl get networkpolicies -A
```

### Tear Down (preserve credits)

```bash
./scripts/teardown.sh
# Prompts for "OMNISSIAH" confirmation
# Runs terraform destroy in terraform/environments/dev
```

### Attack→Detect Demo

```bash
./scripts/attack-sim.sh
# Fires scripted attack scenarios against myrmidon target pods
# Check Wazuh dashboard — alert should appear within 60s
```

---

## Cost Management

| Resource | Cost | Notes |
|----------|------|-------|
| AKS cluster (1x B2s) | ~$0.04/hr | Destroy between sessions |
| Azure Static Web App | $0 | Free tier, always-on |
| ACR Basic | ~$5/mo | Minimal if usage is low |
| Key Vault | ~$0.03/month | Negligible |
| Log Analytics | Pay-per-GB | 30-day retention, minimal traffic |

**Rule:** AKS is on-demand only. `terraform apply` before demo, `teardown.sh` after. The $200 free credit lasts months at this rate.

---

## Repo Structure

```
temporia/
├── terraform/
│   ├── environments/dev/      # Root module, backend config, tfvars example
│   └── modules/               # networking, aks, acr, keyvault, monitoring
├── helm/charts/temporia-stack/ # Baseline security posture chart
├── scripts/                   # bootstrap.sh, teardown.sh, attack-sim.sh, lab-status.sh, ioc-scan.sh
├── dashboard/src/             # Static Web App (index.html, style.css, app.js)
├── docs/                      # Architecture (this file) + research write-ups
├── .github/workflows/         # CI: terraform-validate, helm-lint, shellcheck
├── ISA.md                     # Ideal State Artifact (E4, 166 ISCs)
└── README.md
```

---

## Session Roadmap

| Session | Focus |
|---------|-------|
| **1 (complete)** | Scaffolding — Terraform modules, Helm chart, scripts, dashboard, CI |
| **2** | Azure provision, AKS setup, cert-manager, ingress, Wazuh + Falco deployment |
| **3** | Offensive tooling, attack-sim.sh → Wazuh alert pipeline, full purple team demo |
| **4** | Dashboard live on Azure Static Web Apps, portfolio polish, write-up |

---

*Built by Conrad Hoffman · [github.com/YOURUSER/temporia](https://github.com/YOURUSER/temporia)*
