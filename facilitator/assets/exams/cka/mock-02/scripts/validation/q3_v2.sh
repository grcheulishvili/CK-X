#!/bin/bash
# Accept either form of consuming the db-creds secret:
#   1. envFrom: secretRef.name == db-creds   (kubectl set env --from=... with no --keys / manual envFrom)
#   2. env[].valueFrom.secretKeyRef.name == db-creds  (kubectl set env --from=secret/db-creds produces this)
JSON=$(kubectl get deployment app-deploy -o json)

# Form 1: envFrom -> secretRef
echo "$JSON" | jq -e '.spec.template.spec.containers[0].envFrom[]? | select(.secretRef.name=="db-creds")' > /dev/null 2>&1 && exit 0

# Form 2: env -> valueFrom.secretKeyRef
echo "$JSON" | jq -e '.spec.template.spec.containers[0].env[]? | select(.valueFrom.secretKeyRef.name=="db-creds")' > /dev/null 2>&1 && exit 0

echo "Deployment app-deploy does not consume secret db-creds via envFrom or secretKeyRef"
exit 1
