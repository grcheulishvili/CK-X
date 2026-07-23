#!/bin/bash
# RoleBinding dev-binding in staging must bind the User dev-user.
set -o pipefail
kubectl get rolebinding dev-binding -n staging -o json 2>/dev/null \
  | jq -e '.subjects[]? | select(.name=="dev-user" and .kind=="User")' >/dev/null
