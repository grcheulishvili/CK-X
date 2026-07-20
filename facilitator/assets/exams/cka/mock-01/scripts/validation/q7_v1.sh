#!/bin/bash
kubectl -n web get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}' | grep -qx nginx:1.26
