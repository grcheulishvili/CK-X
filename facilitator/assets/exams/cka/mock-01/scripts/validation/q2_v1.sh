#!/bin/bash
# Role dev-role in staging must allow list on pods.
# NOTE: `jq 'select(...)'` exits 0 even when nothing matches, so -e is required
# or this check can never fail.
set -o pipefail
kubectl get role dev-role -n staging -o json 2>/dev/null \
  | jq -e '.rules[] | select((.resources[]? | contains("pods")) and (.verbs[]? | contains("list")))' >/dev/null
