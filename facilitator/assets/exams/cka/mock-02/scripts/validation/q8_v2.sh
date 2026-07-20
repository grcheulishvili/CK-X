#!/bin/bash
kubectl get pod init-demo -n default -o json | jq -e '.spec.volumes[] | select(.name=="work") | .emptyDir' >/dev/null
