#!/bin/bash
[ "$(kubectl -n apps get deploy cfg-app -o jsonpath='{.status.availableReplicas}')" = "1" ]
