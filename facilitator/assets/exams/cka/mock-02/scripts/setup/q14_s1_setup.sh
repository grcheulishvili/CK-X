#!/bin/bash
kubectl -n default delete deploy web2 --ignore-not-found >/dev/null 2>&1 || true
kubectl -n default delete svc web2-svc --ignore-not-found >/dev/null 2>&1 || true
kubectl create deployment web2 --image=nginx
kubectl expose deployment web2 --name=web2-svc --port=80 --target-port=8080
