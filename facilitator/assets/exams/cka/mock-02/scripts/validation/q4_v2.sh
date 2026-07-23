#!/bin/bash
# DaemonSet monitoring-agent must tolerate the control-plane NoSchedule taint.
set -o pipefail
kubectl get daemonset monitoring-agent -o json 2>/dev/null \
  | jq -e '.spec.template.spec.tolerations[]? | select(.key=="node-role.kubernetes.io/control-plane" and .effect=="NoSchedule")' >/dev/null
