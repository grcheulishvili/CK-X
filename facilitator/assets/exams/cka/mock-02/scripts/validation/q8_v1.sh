#!/bin/bash
kubectl get pod init-demo -n default -o jsonpath='{.spec.initContainers[0].image}' | grep -q busybox
