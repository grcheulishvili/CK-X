#!/bin/bash
kubectl get pod pvc-pod -n default -o json | jq -e '.spec.volumes[] | select(.persistentVolumeClaim.claimName=="data-pvc")' >/dev/null && kubectl get pod pvc-pod -n default -o json | jq -e '.spec.containers[0].volumeMounts[] | select(.mountPath=="/data")' >/dev/null
