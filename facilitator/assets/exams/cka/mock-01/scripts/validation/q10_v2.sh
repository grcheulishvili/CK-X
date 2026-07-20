#!/bin/bash
svc=$(kubectl -n web get ingress web-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}')
port=$(kubectl -n web get ingress web-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}')
[ "$svc" = "web-svc" ] && [ "$port" = "80" ]
