#!/bin/bash
kubectl delete deployment broken-app -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl create deployment broken-app --image=nginx:doesnotexist-999 -n default
