#!/bin/bash
kubectl get pod pending-pod -n default -o jsonpath='{.status.phase}' | grep -qx Running
