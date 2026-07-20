#!/bin/bash
[ -n "$(kubectl -n store get endpoints api-svc -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]
