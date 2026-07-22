#!/usr/bin/env python3
"""Generate facilitator/assets/exams/EXAMS.md from labs.json + assessments."""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EX = os.path.join(ROOT, "facilitator", "assets", "exams")

labs = {l["id"]: l for l in json.load(open(os.path.join(EX, "labs.json")))["labs"]}
rows = []
for l in labs.values():
    ap = os.path.join(ROOT, "facilitator", l["assetPath"])
    aj = os.path.join(ap, "assessment.json")
    nq = 0
    if os.path.isfile(aj):
        nq = len(json.load(open(aj)).get("questions", []))
    l["questionCount"] = nq  # keep labs.json in sync for the UI catalog
    rows.append((l, nq))

order = {"CKA": 0, "CKAD": 1, "CKS": 2, "Other": 3}
rows.sort(key=lambda r: (order.get(r[0]["category"], 9), r[0]["id"]))

out = [
    "# CK-X Exam Index",
    "",
    "_Auto-generated from `labs.json` + each `assessment.json`. Regenerate with `python3 scripts/gen-index.py`._",
    "",
    "| ID | Category | Name | Questions | Difficulty | Duration |",
    "|----|----------|------|-----------|------------|----------|",
]
for l, nq in rows:
    out.append(f"| `{l['id']}` | {l['category']} | {l['name']} | {nq} | {l['difficulty']} | {l['examDurationInMinutes']} min |")

out += [
    "",
    "## Environment notes",
    "",
    "- Candidates SSH to the single node shown in each question, now named **`controlplane`** (exam convention). "
    "Note the two naming layers: the SSH host / shell prompt is `controlplane`, while `kubectl get nodes` shows the "
    "k3d object names `k3d-cluster-server-0` (control plane) and `k3d-cluster-agent-0..N` (workers) — validators and "
    "node-affinity/taint tasks use those object names. Worker count per exam is set by `workerNodes` in `config.json`.",
    "- Default CNI is **flannel**, which does **not** enforce NetworkPolicy. NetworkPolicy questions are graded "
    "on the policy **spec**, not on live connectivity.",
    "- k3s ships **Traefik** (ingress) and **local-path** (default StorageClass) — Ingress and dynamic-PVC "
    "questions rely on these.",
    "- Setup scripts run only if they match the glob `q*_setup.sh`; validators are executed by path, so a valid "
    "shebang and LF line endings are required. Run `python3 scripts/lint-exams.py` before committing changes.",
    "",
]
open(os.path.join(EX, "EXAMS.md"), "w", newline="\n").write("\n".join(out) + "\n")
print("wrote", os.path.join(EX, "EXAMS.md"))
