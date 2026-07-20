#!/bin/bash
kubectl get pod init-demo -n default -o json | jq -e '.spec.containers[] | select(.image|test("nginx")) | .volumeMounts[] | select(.name=="work" and .mountPath=="/usr/share/nginx/html")' >/dev/null
