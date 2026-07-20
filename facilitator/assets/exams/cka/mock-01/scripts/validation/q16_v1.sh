#!/bin/bash
kubectl get pvc app-pvc -n default -o jsonpath='{.status.phase}' | grep -qx Bound
