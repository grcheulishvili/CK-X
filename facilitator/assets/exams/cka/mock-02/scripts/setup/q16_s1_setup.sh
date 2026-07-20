#!/bin/bash
kubectl -n default delete deploy np-app --ignore-not-found >/dev/null 2>&1 || true
kubectl -n default delete svc np-svc --ignore-not-found >/dev/null 2>&1 || true
kubectl create deployment np-app --image=nginx
