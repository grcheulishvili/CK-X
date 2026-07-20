# CKA / CKS Readiness Map — what this simulator does and does not prepare you for

The real CKA/CKS are hands-on: pattern recognition, troubleshooting, and `kubectl` muscle
memory under a 2-hour clock. This lab is very good for most of that — **but it runs on
k3d (k3s-in-docker), not a kubeadm cluster**, and that boundary decides what can and cannot
be practiced here for real. Read this before you rely on it as your only prep.

---

## 1. What the k3d environment can and cannot test

| Exam area | Real exam | This simulator |
|-----------|-----------|----------------|
| Create / edit / troubleshoot API objects (pods, deploys, svcs, cfgmaps, secrets, PV/PVC, RBAC, jobs, netpol specs) | live | **Live, fully graded** — this is ~60–65% of CKA and the sim nails it |
| Scheduling (nodeSelector, affinity, taints/tolerations, priorityclass) | live | **Live** |
| Rollouts / rollback / scaling | live | **Live** |
| App troubleshooting (CrashLoop, ImagePull, Pending, probes, config/secret errors, service selector/port) | live | **Live** — the highest-value practice here |
| Ingress | live (nginx ingress) | **Live** (k3s ships Traefik) |
| Dynamic storage / default StorageClass | live | **Live** (k3s ships `local-path`) |
| **NetworkPolicy runtime enforcement** | CNI enforces | **Spec-only** — flannel does **not** enforce. You practice writing correct policy; you cannot see traffic actually blocked here. |
| **kubeadm install / join / upgrade** | live on real nodes | **Recall only** (command-file tasks). No kubeadm here. |
| **etcd backup / restore** | live against static-pod etcd | **Recall only** — k3d has no static-pod etcd. |
| **Static pods, editing `/etc/kubernetes/manifests`, cert renewal** | live, SSH to node | **Not testable** — you don't get an OS-level node shell. |
| **Node-level troubleshooting** (kubelet down, CNI broken, swap, `journalctl -u kubelet`) | live | **Recall only** |

### The honest gap
Roughly the **kubeadm / etcd / static-pod / node-OS slice of Cluster Architecture (25%) and
control-plane Troubleshooting (30%)** cannot be practiced *for real* in k3d. In this repo those
appear as **command-recall tasks** (write the exact command to a file, which is graded) so you
still build the muscle memory — but you must also practice them on a **real kubeadm cluster**
(VMs / cloud instances) or on **killer.sh** (free with your exam voucher). Do not skip that.

---

## 2. Mock exam domain coverage (CKA blueprint = 25 / 15 / 20 / 10 / 30)

Both mocks are 17 tasks in 120 minutes, weighted toward the real blueprint. Troubleshooting is
now the largest domain, matching the exam.

| Domain (target) | mock-01 | mock-02 | combined |
|-----------------|:-------:|:-------:|:--------:|
| Cluster Architecture (25%) | 3 | 4 | 21% |
| Workloads & Scheduling (15%) | 4 | 5 | 26% |
| Services & Networking (20%) | 3 | 1* | 12–24%* |
| Storage (10%) | 1 | 2 | 9% |
| Troubleshooting (30%) | 6 | 5 | **32%** |

\* Several networking tasks (service selector / targetPort fixes) are counted under
Troubleshooting because that's the skill under test; real networking exposure is higher than the
raw 12% suggests (Ingress, NodePort, NetworkPolicy AND/OR, DNS, ClusterIP are all present).

The `cka/001` and `cka/002` **practice labs** are intentionally object-drill heavy (Workloads /
Storage) — use them to build speed on specific resource types, and use the **mocks** for timed,
exam-shaped simulation.

---

## 3. High-frequency patterns now covered (the muscle-memory checklist)

- **Troubleshooting:** CrashLoopBackOff (bad command / missing config file), ImagePullBackOff,
  Pending (unschedulable resource request), readiness/liveness probe misconfig, ConfigMap/Secret
  missing, Service selector mismatch, Service wrong targetPort, PVC won't bind (capacity mismatch).
- **Cluster architecture:** RBAC Role/RoleBinding + `auth can-i`, node drain/cordon/uncordon,
  ServiceAccount, etcd backup **and** restore (recall), kubeadm node upgrade sequence (recall),
  API-server log inspection (recall).
- **Workloads/scheduling:** deploy create/scale/image-update/rollback, nodeSelector, taints &
  tolerations, PriorityClass, DaemonSet toleration, QoS (requests==limits), CronJob, init container.
- **Networking:** ClusterIP, NodePort with a fixed nodePort, Ingress (Traefik), the NetworkPolicy
  namespaceSelector-**AND**-podSelector vs OR trap, cross-namespace DNS FQDN.
- **Storage:** static PV/PVC binding (incl. RWX), dynamic PVC via `local-path`, mount into a pod.

---

## 4. How to run a realistic timed mock

1. Start a mock, set a hard **120-minute** timer, no docs except `kubernetes.io/docs`,
   `helm.sh/docs`, and (CKS) `falco.org/docs`.
2. First 60 seconds, set up your shell: `alias k=kubectl`, `source <(kubectl completion bash)`,
   `export KUBE_EDITOR=vim`, `complete -F __start_kubectl k`.
3. Triage by weight; **time-box each task to ~5 minutes** and flag anything longer.
4. `kubectl get <resource> -n <ns>` after every task — verify before moving on.
5. Grade, then review **every** missed task against `answers.md`. Re-attempt failures cold the
   next day. The exam rewards repetition of the same ~40 patterns until they're automatic.

Passing marks: CKA ≈ **66%**, CKS ≈ **67%**. Aim to consistently clear **80%** here before
booking, because the real clock and unfamiliar cluster contexts cost time.

---

## 5. CKS status and next steps

`cks/001` covers the object-gradeable slice of CKS well: NetworkPolicy, RBAC least-privilege,
Pod Security Admission labels, securityContext (non-root, read-only FS, dropped capabilities),
ServiceAccount token automount, secrets. The parts of CKS that need node/host access —
**Falco rule authoring + reload, AppArmor/seccomp profile loading, Trivy/kubesec scanning,
API-server audit-policy and encryption-at-rest, ImagePolicyWebhook** — are only partially
representable here for the same k3d reasons above and should be drilled on killer.sh.
A second CKS mock (`cks-002`) shaped like these CKA mocks is the recommended next addition.

---

## 6. Where to supplement (do not skip)

- **killer.sh** — free with your CKA/CKS voucher, kubeadm-based, harder than the real exam; the
  single best complement to this sim for the node/etcd/kubeadm gaps.
- **A kubeadm cluster in VMs** — practice install, `kubeadm upgrade`, etcd backup/restore, static
  pod edits, cert renewal, and node-NotReady recovery for real at least twice.
- Official curriculum + `kubernetes.io/docs` navigation speed.
