#!/bin/bash
kubectl -n production get networkpolicy backend-allow -o json | jq -e '.spec.ingress[0].from | length==1 and (.[0]|has("namespaceSelector") and has("podSelector"))' >/dev/null
