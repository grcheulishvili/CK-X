#!/bin/bash
P=guaranteed-pod
rc=$(kubectl get pod $P -o jsonpath='{.spec.containers[0].resources.requests.cpu}')
rm=$(kubectl get pod $P -o jsonpath='{.spec.containers[0].resources.requests.memory}')
lc=$(kubectl get pod $P -o jsonpath='{.spec.containers[0].resources.limits.cpu}')
lm=$(kubectl get pod $P -o jsonpath='{.spec.containers[0].resources.limits.memory}')
[ "$rc" = "200m" ] && [ "$lc" = "200m" ] && [ "$rm" = "128Mi" ] && [ "$lm" = "128Mi" ]
