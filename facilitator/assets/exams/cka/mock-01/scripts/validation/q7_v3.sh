#!/bin/bash
[ "$(kubectl -n web get deploy web -o jsonpath='{.status.availableReplicas}')" = "5" ]
