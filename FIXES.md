# CK-X Local Lab — Fixes Applied (CKA / CKS focus)

## Environment facts that drive several fixes
- The cluster is **k3d (k3s-in-docker)**, despite the directory being named `kind-cluster`.
- Node names are `k3d-cluster-server-0` (control plane) and `k3d-cluster-agent-0`, `k3d-cluster-agent-1` (workers), governed by `workerNodes` in each exam's `config.json`.
- Default CNI is **flannel**, which **does NOT enforce NetworkPolicy**. Any validator that tests NetworkPolicy *runtime effect* (e.g. "this pod must be blocked") is unreliable and must validate the policy *spec* instead.

## ⚠️ BIGGEST ISSUE — CRLF line endings (repo-wide)
**523 of 560 shell scripts had Windows CRLF (`\r\n`) line endings.** When executed by
`/bin/bash` inside the Linux jumphost/cluster containers, the trailing `\r` causes
"syntax error near `\r`", "unexpected end of file", and broken `fi`/`done`/here-docs —
so the vast majority of setup and validation scripts would fail regardless of the
candidate's answer. This single defect dwarfed every individual logic bug.

Fix applied:
- Converted **all 560 `.sh` files** to LF and set the executable bit (the facilitator
  runs them by path, so `+x` is required — 413 were missing it).
- Also normalized CRLF→LF in all `.py` files, `Dockerfile`s, and container entrypoints
  (`entrypoint.sh`, `startup.sh`, `init.sh`, `agent.py`) where `\r` breaks shebang/RUN lines.
- Left JS/JSON/YAML/conf untouched (Node, nginx, docker-compose tolerate CRLF).

Verification: `bash -n` over the entire repo now reports **0 syntax errors** (was 500+).

## Additional real bug fixed
- **other/002 (Helm) `q9_s1_validate_chart_created.sh`**: a `for … do` loop was closed
  with `fi` instead of `done` — a hard syntax error independent of CRLF. Fixed.

## Confirmed bugs fixed

### CKA mock-01
1. **Q3** references node `worker-1`, which does not exist in k3d.
   - `scripts/setup/q3_s1_setup.sh`: uncordon `worker-1` → `k3d-cluster-agent-0`
   - `scripts/validation/q3_v1.sh`: check `worker-1` → `k3d-cluster-agent-0`
   - `assessment.json` Q3 text: `worker-1` → `k3d-cluster-agent-0`
   - `answers.md` Q3: same rename.

### CKA mock-02
2. **Q3** answer uses `kubectl set env --from=secret/...` which produces
   `env[].valueFrom.secretKeyRef`, but validator `q3_v2.sh` only accepted `envFrom[].secretRef`.
   Following the official answer would fail. Validator now accepts **either** form.

### CKS 001
3. **Q8 `q8_s4_validate_restricted_access.sh`** is a NetworkPolicy *runtime-blocking*
   test. Under flannel the policy is not enforced, so a correct answer is graded wrong.
   Rewritten to validate the policy spec (egress default-deny via except-API-server block)
   instead of live connectivity.

### Other / Docker 001 (included since user said "whatever's there")
4. **Q15 & Q16** reference 5 validation scripts that **do not exist**, making those
   questions ungradeable (always 0). Created the missing scripts:
   - q15_s1_validate_dockerfile.sh, q15_s2_validate_dockerignore.sh, q15_s3_validate_size.sh
   - q16_s1_validate_dct_enabled.sh, q16_s2_validate_commands.sh

## Notes / left intentionally as-is
- **CKS orphan scripts** (q13–q20 etc.): leftovers from an older 20-question version of the
  CKS exam. The live exam (`assessment.json`) is 12 questions. Orphans are not referenced and
  do not affect grading; left in place (deleting could break a future re-expansion).
- **answers.md (CKS)** still documents 20 questions while the exam is 12. Trimmed to match
  the live 12 questions to avoid confusing learners.
- **Helm Q11 (cka/002)**: depends on the public Bitnami repo, which has been
  restructured upstream and may fail to pull images in 2025+. This is an upstream/network
  issue, not a script bug; documented in answers, not "fixed" by altering logic.
- **Gateway API Q13 (cka/002)**: installs CRDs from GitHub at setup; k3s has no Gateway
  controller, so validators correctly check spec only (the Ready-status checks are already
  commented out). Left as-is.
