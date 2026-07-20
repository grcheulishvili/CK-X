#!/bin/bash
kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apps delete deploy cfg-app --ignore-not-found >/dev/null 2>&1 || true
kubectl -n apps delete configmap app-cfg --ignore-not-found >/dev/null 2>&1 || true
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cfg-app
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cfg-app
  template:
    metadata:
      labels:
        app: cfg-app
    spec:
      containers:
      - name: app
        image: nginx
        envFrom:
        - configMapRef:
            name: app-cfg
EOF
