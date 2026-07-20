#!/bin/bash
kubectl get pod crash-pod -n default -o jsonpath='{.status.phase}' | grep -qx Running
