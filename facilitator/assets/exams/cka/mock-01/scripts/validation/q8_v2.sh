#!/bin/bash
kubectl get pod guaranteed-pod -o jsonpath='{.status.qosClass}' | grep -qx Guaranteed
