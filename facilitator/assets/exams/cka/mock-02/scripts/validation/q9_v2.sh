#!/bin/bash
kubectl get pod sa-pod -n default -o jsonpath='{.spec.serviceAccountName}' | grep -qx build-sa
