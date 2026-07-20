#!/bin/bash
kubectl get svc np-svc -o jsonpath='{.spec.type}' | grep -qx NodePort && [ "$(kubectl get svc np-svc -o jsonpath='{.spec.ports[0].port}')" = "80" ] && [ "$(kubectl get svc np-svc -o jsonpath='{.spec.ports[0].nodePort}')" = "30080" ]
