#!/bin/bash
[ -n "$(kubectl -n web get endpoints web-svc -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]
