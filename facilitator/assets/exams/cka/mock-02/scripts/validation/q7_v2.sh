#!/bin/bash
kubectl get pod toleration-pod -n default -o jsonpath='{.spec.tolerations[*].key}' | grep -q dedicated
