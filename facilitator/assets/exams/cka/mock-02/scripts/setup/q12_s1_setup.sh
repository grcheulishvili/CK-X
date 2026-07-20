#!/bin/bash
kubectl delete deployment frontend -n default --ignore-not-found >/dev/null 2>&1 || true
kubectl create deployment frontend --image=nginx -n default
kubectl patch deployment frontend -n default --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/readinessProbe","value":{"httpGet":{"path":"/","port":8080},"initialDelaySeconds":3,"periodSeconds":5}}]'
