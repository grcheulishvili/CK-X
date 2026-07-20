#!/bin/bash
[ "$(kubectl get deploy frontend -n default -o jsonpath='{.status.availableReplicas}')" = "1" ]
