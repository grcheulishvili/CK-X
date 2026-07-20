#!/bin/bash
[ "$(kubectl get deploy frontend -n default -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')" = "80" ]
