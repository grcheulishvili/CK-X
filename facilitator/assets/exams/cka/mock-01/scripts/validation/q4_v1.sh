#!/bin/bash
# PV db-pv: 5Gi, ReadWriteMany, storageClassName fast-ssd.
set -o pipefail
kubectl get pv db-pv -o json 2>/dev/null \
  | jq -e '.spec | select(.capacity.storage=="5Gi" and (.accessModes|index("ReadWriteMany")) and .storageClassName=="fast-ssd")' >/dev/null
