#!/bin/bash
F=/tmp/exam/q6_etcd_backup.txt
[ -f "$F" ] || exit 1
grep -q 'etcdctl' "$F" && grep -q 'snapshot save' "$F" && grep -q -- '--endpoints' "$F" && grep -q -- '--cacert' "$F" && grep -q -- '--cert' "$F" && grep -q -- '--key' "$F"
