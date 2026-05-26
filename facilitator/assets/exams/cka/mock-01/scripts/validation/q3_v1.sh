#!/bin/bash
kubectl get node k3d-cluster-agent-0 -o jsonpath='{.spec.unschedulable}' | grep -q 'true'