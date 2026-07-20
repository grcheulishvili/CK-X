#!/bin/bash
[ "$(kubectl get svc web2-svc -o jsonpath='{.spec.ports[0].targetPort}')" = "80" ]
