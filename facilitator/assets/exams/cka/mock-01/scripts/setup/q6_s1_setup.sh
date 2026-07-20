#!/bin/bash
kubectl label node k3d-cluster-agent-0 disktype- --overwrite >/dev/null 2>&1 || true
kubectl delete pod ssd-pod -n default --ignore-not-found >/dev/null 2>&1 || true
