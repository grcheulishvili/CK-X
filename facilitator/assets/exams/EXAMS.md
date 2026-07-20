# CK-X Exam Index

_Auto-generated from `labs.json` + each `assessment.json`. Regenerate with `python3 scripts/gen-index.py`._

| ID | Category | Name | Questions | Difficulty | Duration |
|----|----------|------|-----------|------------|----------|
| `cka-001` | CKA | CKA Practice Lab - Core Concepts | 10 | Easy | 60 min |
| `cka-002` | CKA | CKA Practice Lab - Advanced Administration | 20 | Hard | 120 min |
| `cka-mock-01` | CKA | CKA Mock Exam 01 | 17 | Hard | 120 min |
| `cka-mock-02` | CKA | CKA Mock Exam 02 | 17 | Hard | 120 min |
| `ckad-001` | CKAD | CKAD Comprehensive Lab - 1 | 21 | Medium | 120 min |
| `ckad-002` | CKAD | CKAD Comprehensive Lab - 2 | 20 | Hard | 120 min |
| `cks-001` | CKS | CKS Practice Lab - Kubernetes Security Essentials | 12 | Hard | 120 min |
| `docker-001` | Other | Docker Speed Run - Core Concepts | 16 | Medium | 90 min |
| `helm-001` | Other | Helm Fundamentals Lab | 12 | Medium | 90 min |

## Environment notes

- Candidates SSH to the single node shown in each question, now named **`controlplane`** (exam convention). Note the two naming layers: the SSH host / shell prompt is `controlplane`, while `kubectl get nodes` shows the k3d object names `k3d-cluster-server-0` (control plane) and `k3d-cluster-agent-0..N` (workers) — validators and node-affinity/taint tasks use those object names. Worker count per exam is set by `workerNodes` in `config.json`.
- Default CNI is **flannel**, which does **not** enforce NetworkPolicy. NetworkPolicy questions are graded on the policy **spec**, not on live connectivity.
- k3s ships **Traefik** (ingress) and **local-path** (default StorageClass) — Ingress and dynamic-PVC questions rely on these.
- Setup scripts run only if they match the glob `q*_setup.sh`; validators are executed by path, so a valid shebang and LF line endings are required. Run `python3 scripts/lint-exams.py` before committing changes.

