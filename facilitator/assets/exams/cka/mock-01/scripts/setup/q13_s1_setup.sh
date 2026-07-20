#!/bin/bash
kubectl create namespace store --dry-run=client -o yaml | kubectl apply -f -
kubectl -n store delete deploy api --ignore-not-found >/dev/null 2>&1 || true
kubectl -n store delete svc api-svc --ignore-not-found >/dev/null 2>&1 || true
kubectl -n store create deployment api --image=nginx
kubectl -n store expose deployment api --name=api-svc --port=80 --target-port=80
kubectl -n store patch svc api-svc -p '{"spec":{"selector":{"app":"wrong-label"}}}'
