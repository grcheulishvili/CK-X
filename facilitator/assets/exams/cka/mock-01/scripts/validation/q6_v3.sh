#!/bin/bash
kubectl get pod ssd-pod -n default -o jsonpath='{.spec.nodeName}' | grep -qx k3d-cluster-agent-0
