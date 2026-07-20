#!/bin/bash
kubectl get pod toleration-pod -n default -o jsonpath='{.status.phase}' | grep -qx Running
