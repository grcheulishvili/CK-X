#!/bin/bash
kubectl get cronjob backup -n default -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0]}' | grep -q date
