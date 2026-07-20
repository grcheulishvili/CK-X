#!/bin/bash
kubectl -n web get svc web-svc -o jsonpath='{.spec.type}' | grep -qx ClusterIP && [ "$(kubectl -n web get svc web-svc -o jsonpath='{.spec.ports[0].port}')" = "80" ]
