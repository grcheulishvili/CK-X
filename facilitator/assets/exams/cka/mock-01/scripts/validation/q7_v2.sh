#!/bin/bash
[ "$(kubectl -n web get deploy web -o jsonpath='{.spec.replicas}')" = "5" ]
