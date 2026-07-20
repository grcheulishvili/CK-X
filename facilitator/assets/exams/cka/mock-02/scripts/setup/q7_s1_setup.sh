#!/bin/bash
kubectl taint node k3d-cluster-agent-0 dedicated- >/dev/null 2>&1 || true
kubectl delete pod toleration-pod -n default --ignore-not-found >/dev/null 2>&1 || true
