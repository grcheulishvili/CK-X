#!/bin/bash
[ "$(kubectl get deploy broken-app -n default -o jsonpath='{.status.availableReplicas}')" = "1" ]
