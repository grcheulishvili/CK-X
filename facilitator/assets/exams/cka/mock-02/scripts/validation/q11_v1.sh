#!/bin/bash
kubectl get pvc data-pvc -n default -o jsonpath='{.status.phase}' | grep -qx Bound
