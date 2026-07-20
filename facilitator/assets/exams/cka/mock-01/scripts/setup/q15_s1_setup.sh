#!/bin/bash
kubectl delete pod crash-pod -n default --ignore-not-found >/dev/null 2>&1 || true
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: crash-pod
  namespace: default
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","exit 1"]
EOF
