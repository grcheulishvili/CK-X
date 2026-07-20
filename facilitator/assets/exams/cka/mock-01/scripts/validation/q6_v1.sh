#!/bin/bash
kubectl get node k3d-cluster-agent-0 -o jsonpath='{.metadata.labels.disktype}' | grep -qx ssd
