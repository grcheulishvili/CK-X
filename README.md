# CK-X Simulator Enhanced Ed.

This repository is an optimized fork of the original `sailor-sh/CK-X` simulator. It introduces critical structural patches, automated environment deployment tooling, and fills major coverage gaps by integrating comprehensive **CKS (Certified Kubernetes Security Specialist)** mock exams and validation matrices that were absent in the upstream repository.

---

## What's New in this Fork

### 1. Extended Exam & Lab Coverage
*   **CKS Mock Exam 01 Integration:** Full deployment of dedicated CKS lab scenarios including AppArmor profiles, Falco runtime security rules, Trivy image vulnerability scanners, NetworkPolicies, and API server auditing verification.
*   **Complete Verification Logic:** Populated missing step-by-step setup (`setup.sh`) and multi-stage shell validation scripts (`validation/q*_v*.sh`) to guarantee accurate automated grading.

### 2. Platform Stability & Structural Fixes
*   **RDP/VNC Recovery:** Resolved terminal image rendering and workspace connection issues inside the `remote-desktop` container.
*   **Cross-Platform Line Ending Normalization:** Embedded configuration protections to stop Windows carriage returns (`CRLF`) from corrupting Linux entrypoint scripts (`/bin/bash^M: bad interpreter` errors).
*   **Local Build Automation:** Enhanced the standalone `compose-deploy.sh` engine to handle multi-container build cycles locally without dependency breaking.

---

##  Fork Installation

Ensure your local Docker engine is running. For Windows environments, verify that the WSL2 engine backend is fully enabled in your Docker Desktop settings before setup.

#### Automated Setup (Linux & macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/grcheulishvili/CK-X/master/scripts/install.sh | bash

```

#### Automated Setup (Windows PowerShell)

```powershell
irm https://raw.githubusercontent.com/grcheulishvili/CK-X/master/scripts/install.ps1 | iex

```

### Manual Dev Setup

To inspect build logs, configure container resource reservations, or modify asset schemas locally:

```bash
git clone git@github.com:grcheulishvili/CK-X.git
cd CK-X

# Execute the local compilation and deployment pipeline
./compose-deploy.sh

```

---

## 📂 Repository Structure Highlights

* `facilitator/assets/exams/cks/` - Dedicated CKS mock engine containing runtime asset controls and verification matrices.
* `remote-desktop/` - Patched VNC server build environments hosting the web-accessible terminal interface.
* `compose-deploy.sh` - Core localization script executing target compilation and orchestrating the decoupled KIND backend.

---

## Disclaimer & License

This fork is maintained independently for optimized exam readiness. Content tracks CNCF/Linux Foundation exam domains but holds no official affiliation. Distributed under the Business Source License 1.1 (BSL 1.1). See the `LICENSE` file for exact data limits.


