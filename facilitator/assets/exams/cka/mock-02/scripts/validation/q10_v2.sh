#!/bin/bash
kubectl get pod prio-pod -n default -o jsonpath='{.spec.priorityClassName}' | grep -qx high-prio
