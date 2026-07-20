#!/bin/bash
kubectl get node k3d-cluster-agent-0 -o jsonpath='{.spec.taints[*].key}' | grep -q dedicated
