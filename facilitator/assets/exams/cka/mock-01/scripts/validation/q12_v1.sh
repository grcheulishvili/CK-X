#!/bin/bash
[ "$(kubectl get cronjob backup -n default -o jsonpath='{.spec.schedule}')" = "*/5 * * * *" ]
