#!/bin/bash
F=/tmp/exam/q17_upgrade.txt
[ -f "$F" ] || exit 1
grep -q 'drain' "$F" && grep -q 'kubeadm upgrade node' "$F" && grep -qi 'kubelet' "$F" && grep -q 'uncordon' "$F"
