#!/bin/bash
# Accept any command that would inspect the kube-apiserver logs.
# Valid on a kubeadm cluster (static pod), via crictl, via on-disk pod logs,
# or via systemd on a k3s/k3d control plane. A kubelet-only command is NOT accepted.
FILE=/tmp/exam/q5_command.txt
[ -f "$FILE" ] || exit 1
grep -qiE 'kube-apiserver' "$FILE" && exit 0
grep -qiE 'journalctl[^|]*-u[[:space:]]*(k3s|apiserver)' "$FILE" && exit 0
exit 1
