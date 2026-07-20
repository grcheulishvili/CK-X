#!/bin/bash
kubectl get deploy broken-app -n default -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -qx nginx:1.25
