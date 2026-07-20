#!/bin/bash
[ "$(kubectl get priorityclass high-prio -o jsonpath='{.value}')" = "1000000" ]
