#!/bin/bash
kubectl -n apps get configmap app-cfg -o jsonpath='{.data.MODE}' | grep -qx prod
