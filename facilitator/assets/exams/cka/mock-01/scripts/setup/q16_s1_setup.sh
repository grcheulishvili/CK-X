#!/bin/bash
kubectl delete pvc app-pvc -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pv small-pv --ignore-not-found >/dev/null 2>&1 || true
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: small-pv
spec:
  capacity:
    storage: 100Mi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/small
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: default
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
EOF
