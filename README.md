# Temporia

> **Temporia** is a Dark Mechanicum Forge World — a sanctioned-heretek research station of the Adeptus Mechanicus where the Machine God's tools are turned to forbidden ends. Here, the cult of the Omnissiah builds, breaks, and studies the war-machine in equal measure.

Temporia is an Azure-hosted **purple team security research lab**. It is a single, self-contained environment for offensive research, defensive detection engineering, and the controlled collision of the two — built on infrastructure-as-code so the whole forge can be raised from cold metal and returned to the warp on demand.

![Terraform](https://img.shields.io/badge/Terraform-1.7%2B-7B42BC?logo=terraform&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-3.14-0F1689?logo=helm&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-Scripting-4EAA25?logo=gnubash&logoColor=white)

---

## Architecture Overview

The forge has two halves: a local development half on the Mac (fast, free, ephemeral via k3d) and the Azure half (the real cluster, raised only when needed).

```
┌───────────────────────────────┐          ┌──────────────────────────────────────────────────┐
│            MAC (local)         │          │                    AZURE                           │
│                                │          │                                                    │
│   ┌─────────────────────────┐  │          │   ┌────────────────────────────────────────────┐   │
│   │  k3d  temporia-dev      │  │  az /    │   │  VNet  temporia-vnet (10.0.0.0/16)          │   │
│   │  (1 server, 2 agents)   │  │  kubectl │   │   ├─ magos-cluster-subnet   (10.0.1.0/24)   │   │
│   │  local Helm test target │◄─┼──────────┼──►│   └─ forge-services-subnet  (10.0.2.0/24)   │   │
│   └─────────────────────────┘  │          │   │                                            │   │
│                                │          │   │  NSG  omnissiah-gate (deny-all + HTTPS/API) │   │
│   terraform / helm / trivy     │          │   │                                            │   │
│   shellcheck / gh / jq         │          │   │  AKS   magos-cluster   (forgepool nodes)    │   │
│                                │          │   │  ACR   temperiaforge   (image registry)     │   │
└───────────────────────────────┘          │   │  KV    temporia-sanctum (secrets)           │   │
                                            │   │  LAW   temporia-archive (logs, 30d)         │   │
                                            │   └────────────────────────────────────────────┘   │
                                            │                                                    │
                                            │   Static Web App  noosphere-dashboard (free tier)  │
                                            └──────────────────────────────────────────────────┘
```

The dashboard (**noosphere-dashboard**) lives on the Azure Static Web Apps free tier and stays up even when the cluster is torn down — it is the lab's always-on status pane.

---

## 40k Naming Taxonomy

Every name in Temporia maps to a piece of Adeptus Mechanicus lore. The mapping is consistent so the infrastructure reads like a story, not a glossary of random codenames.

| Namespace / Resource | 40k Meaning | Purpose |
|----------------------|-------------|---------|
| `temporia` | A Forge World — a planet-sized factory of the Machine Cult | The lab itself |
| `magos-cluster` | A Magos: senior tech-priest who commands the forge | The AKS Kubernetes cluster |
| `forgepool` | The forge's labor pool | The AKS default node pool |
| `temperiaforge` | The great forge of Temporia | Azure Container Registry |
| `temporia-sanctum` | The inner sanctum where sacred data is kept | Azure Key Vault |
| `temporia-archive` | The data-vaults of the Lexmechanic | Log Analytics workspace |
| `omnissiah-gate` | The Omnissiah's warded gate | Network Security Group |
| `noosphere-dashboard` | The Noosphere: the Mechanicum's data-network | Static Web App status dashboard |
| `omnissiah-system` | The tech-priesthood's core | Core-infrastructure namespace |
| `skitarii` | Warrior-cyborgs of the Machine Cult | Defensive / detection workloads |
| `myrmidon` | Heavy-combat destroyer units | Offensive research workloads |
| `lexmechanic` | Data-archivists of the forge | Logging and intelligence |
| `cogitator` | A machine-spirit cognition engine | AI and analysis workloads |

---

## Prerequisites

`scripts/bootstrap.sh` installs everything below on a fresh macOS ARM64 (Apple Silicon) machine:

- **Homebrew** — package manager
- **Azure CLI** (`az`) — Azure control plane
- **Terraform** — infrastructure provisioning
- **kubectl** — Kubernetes control
- **Helm** — Kubernetes package manager
- **k3d** — local Kubernetes-in-Docker for dev
- **OrbStack** — Docker runtime for macOS ARM64 (lighter than Docker Desktop)
- **Trivy** — container image vulnerability scanner
- **gh** — GitHub CLI
- **jq** — JSON processor
- **shellcheck** — shell script linter

You also need an Azure subscription. A free trial covers this lab's on-demand usage comfortably (see Cost Management).

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOURUSER/temporia.git && cd temporia

# 2. Install all tooling (fresh macOS ARM64)
bash scripts/bootstrap.sh

# 3. Authenticate and raise the Azure infrastructure
az login
cd terraform/environments/dev
cp dev.tfvars.example dev.tfvars   # then edit: set owner + allowed_cidr to your IP
terraform init
terraform apply -var-file=dev.tfvars

# 4. Deploy the in-cluster stack (namespaces, network policies, quotas, RBAC)
az aks get-credentials --resource-group temporia-rg --name magos-cluster
helm install temporia-stack helm/charts/temporia-stack
```

When you are done for the day, tear the cloud down (see below) to stop the meter.

---

## Cost Management

AKS spins up on demand via `terraform apply`, tears down via `scripts/teardown.sh`. Free trial covers ~5-6 months of on-demand usage.

The design assumption is **on-demand, not always-on**:

- The cluster (`magos-cluster`) and its node pool are the only meaningful cost. Raise it when you research, destroy it when you stop.
- The dashboard (`noosphere-dashboard`) runs on the Static Web Apps **free tier** and is preserved across teardowns.
- `scripts/teardown.sh` runs `terraform destroy` and removes the AKS cluster, VNet, NSGs, ACR, and Key Vault — everything that bills.
- Rebuild anytime with `terraform apply`. The infrastructure is fully reproducible from code.

```bash
bash scripts/teardown.sh            # interactive confirmation
bash scripts/teardown.sh --confirm  # skip the prompt (CI / scripted use)
```

---

## Security Architecture

Temporia is a **purple team** lab — offense and defense in one environment, instrumented so every attack is also a detection exercise.

- **Red (myrmidon)** — offensive research workloads. Attack tooling, exploit development, and adversary emulation run here, isolated by namespace and network policy.
- **Blue (skitarii)** — defensive and detection workloads. Detection rules, log pipelines, and response tooling watch the lab.
- **Purple loop** — an attack launched from `myrmidon` is meant to be *seen* by `skitarii`: attack → detect → alert → tune. The lab's value is in closing that loop quickly and repeatably.

Hardening defaults baked into Session 1:

- **Default-deny network policies** on every workload namespace; only DNS egress is allowed by default.
- **NSG `omnissiah-gate`** denies all inbound, then explicitly allows only HTTPS (443) and the Kubernetes API (6443) from a configurable CIDR (`allowed_cidr` — set this to your own IP).
- **AcrPull-only** identity binding between the cluster and the registry (no admin user on ACR).
- **Read-only RBAC role** (`temporia-read-only`) that excludes secrets.
- **Centralized logging** to `temporia-archive` (Log Analytics).

---

## Lab Structure

```
temporia/
├── README.md
├── .gitignore
├── terraform/
│   ├── modules/
│   │   ├── networking/      # VNet, subnets, NSG (omnissiah-gate)
│   │   ├── aks/             # magos-cluster
│   │   ├── acr/             # temperiaforge registry + AcrPull binding
│   │   ├── keyvault/        # temporia-sanctum
│   │   └── monitoring/      # temporia-archive (Log Analytics)
│   └── environments/
│       ├── dev/             # dev root module + backend
│       └── prod/            # prod root module + backend
├── scripts/
│   ├── bootstrap.sh         # install all tooling (full impl)
│   ├── teardown.sh          # terraform destroy (full impl)
│   ├── attack-sim.sh        # offensive simulation (Session 3 stub)
│   ├── ioc-scan.sh          # IOC scanning (Session 3 stub)
│   └── lab-status.sh        # status report (Session 3 stub)
├── docker/                  # custom images (Session 2+)
├── dashboard/               # noosphere-dashboard static site
│   ├── src/                 # index.html, style.css, app.js
│   └── staticwebapp.config.json
├── docs/
│   ├── architecture.md      # full architecture document
│   ├── runbooks/
│   └── research/
├── helm/
│   └── charts/
│       └── temporia-stack/  # namespaces, network policies, quotas, RBAC
└── .github/
    └── workflows/
        └── ci.yml           # terraform validate, helm lint, shellcheck
```

---

## Dashboard

Live lab status: `https://YOUR_STATIC_WEBAPP.azurestaticapps.net`

(Replace with your deployed Static Web App URL once `noosphere-dashboard` is provisioned.)

---

*Sanctioned by the Omnissiah. Built with Terraform + Helm + Azure.*
