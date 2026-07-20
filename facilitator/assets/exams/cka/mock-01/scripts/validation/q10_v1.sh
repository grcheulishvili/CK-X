#!/bin/bash
kubectl -n web get ingress web-ingress -o jsonpath='{.spec.rules[0].host}' | grep -qx web.example.com
