#!/bin/bash
J=$(kubectl -n production get networkpolicy backend-allow -o json)
echo "$J" | jq -e '.spec.podSelector.matchLabels.app=="backend"' >/dev/null && echo "$J" | jq -e '.spec.ingress[0].ports[]? | select(.port==8080)' >/dev/null
