#!/bin/bash
kubectl delete priorityclass high-prio --ignore-not-found >/dev/null 2>&1 || true
kubectl delete pod prio-pod -n default --ignore-not-found >/dev/null 2>&1 || true
