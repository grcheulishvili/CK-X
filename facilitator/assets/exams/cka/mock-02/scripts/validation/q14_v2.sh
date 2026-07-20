#!/bin/bash
[ -n "$(kubectl get endpoints web2-svc -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]
