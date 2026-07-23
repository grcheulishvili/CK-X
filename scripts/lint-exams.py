#!/usr/bin/env python3
"""
lint-exams.py  -  Static validator for CK-X exam assets.

Run before committing new labs/questions. Checks, per exam under
facilitator/assets/exams/<cat>/<id>/:

  1. assessment.json / config.json are valid JSON
  2. every verificationScriptFile referenced actually exists
  3. reports orphan validation scripts (exist but unreferenced)
  4. no duplicate question ids
  5. every setup script matches the runtime glob  q*_setup.sh
     (prepare-exam-env only executes files matching that pattern)
  6. no CRLF line endings anywhere in the tree
  7. all *.sh have a shebang and are syntactically valid (bash -n)

Exit code 0 = clean, 1 = problems found.
"""
import json, os, glob, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXAMS = os.path.join(ROOT, "facilitator", "assets", "exams")

errors, warnings = [], []

def err(m): errors.append(m)
def warn(m): warnings.append(m)

# ---- per-exam checks ----
exam_dirs = []
for cat in sorted(os.listdir(EXAMS)):
    catp = os.path.join(EXAMS, cat)
    if not os.path.isdir(catp):
        continue
    for lab in sorted(os.listdir(catp)):
        labp = os.path.join(catp, lab)
        if os.path.isfile(os.path.join(labp, "assessment.json")):
            exam_dirs.append(labp)

for d in exam_dirs:
    rel = os.path.relpath(d, EXAMS)
    try:
        a = json.load(open(os.path.join(d, "assessment.json")))
    except Exception as e:
        err(f"[{rel}] assessment.json invalid: {e}")
        continue
    cfgp = os.path.join(d, "config.json")
    if os.path.isfile(cfgp):
        try:
            json.load(open(cfgp))
        except Exception as e:
            err(f"[{rel}] config.json invalid: {e}")

    qs = a.get("questions", [])
    ids = [q.get("id") for q in qs]
    dup = sorted({i for i in ids if ids.count(i) > 1})
    if dup:
        err(f"[{rel}] duplicate question ids: {dup}")

    ref = [v["verificationScriptFile"] for q in qs for v in q.get("verification", [])]
    valdir = os.path.join(d, "scripts", "validation")
    exist = {os.path.basename(p) for p in glob.glob(os.path.join(valdir, "*.sh"))}
    for missing in sorted(set(ref) - exist):
        err(f"[{rel}] referenced validation script missing: {missing}")
    for orphan in sorted(exist - set(ref)):
        warn(f"[{rel}] orphan validation script (unreferenced): {orphan}")

    setupdir = os.path.join(d, "scripts", "setup")
    for p in glob.glob(os.path.join(setupdir, "*.sh")):
        b = os.path.basename(p)
        if b.startswith("q") and not re.match(r"^q.*_setup\.sh$", b):
            err(f"[{rel}] setup script won't run (glob is q*_setup.sh): {b}")

# ---- tree-wide checks ----
for r, _, files in os.walk(ROOT):
    if os.sep + ".git" in r or "__pycache__" in r or os.sep + "node_modules" in r:
        continue
    for fn in files:
        p = os.path.join(r, fn)
        ext = os.path.splitext(fn)[1].lower()
        if ext in {".zip", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".woff", ".woff2", ".ttf"}:
            continue
        try:
            b = open(p, "rb").read()
        except Exception:
            continue
        if b"\r" in b:
            err(f"CRLF/CR line endings: {os.path.relpath(p, ROOT)}")
        if fn.endswith(".sh"):
            if not b.startswith(b"#!"):
                warn(f"missing shebang: {os.path.relpath(p, ROOT)}")
            r2 = subprocess.run(["bash", "-n", p], capture_output=True, text=True)
            if r2.returncode != 0:
                err(f"bash syntax error: {os.path.relpath(p, ROOT)} :: {r2.stderr.strip().splitlines()[:1]}")
            # A validator that can never fail is worse than no validator: `jq 'select(...)'`
            # exits 0 even when nothing matches, so it must be `jq -e`.
            if os.sep + "validation" + os.sep in p:
                for line in b.decode("utf-8", "replace").split("\n"):
                    ls = line.strip()
                    if not ls or ls.startswith("#"):
                        continue
                    if "jq " in ls and "select(" in ls and not re.search(r"jq\s+-[a-zA-Z]*e\b", ls) \
                            and not re.match(r"^[A-Za-z_]+=", ls):
                        err(f"validator can never fail (needs `jq -e`): {os.path.relpath(p, ROOT)}")
                        break

print(f"Exams scanned: {len(exam_dirs)}")
for w in warnings:
    print("WARN ", w)
for e in errors:
    print("ERROR", e)
print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
sys.exit(1 if errors else 0)
