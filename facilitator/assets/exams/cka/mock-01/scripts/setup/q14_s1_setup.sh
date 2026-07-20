#!/bin/bash
kubectl delete pod pending-pod -n default --ignore-not-found >/dev/null 2>&1 || true
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: pending-pod
  namespace: default
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "200"
EOF
