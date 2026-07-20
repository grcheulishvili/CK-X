#!/bin/bash
kubectl get pod ssd-pod -n default -o jsonpath='{.spec.nodeSelector.disktype}' | grep -qx ssd
