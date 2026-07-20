#!/bin/bash
F=/tmp/exam/q17_etcd_restore.txt
[ -f "$F" ] || exit 1
grep -q 'etcdctl' "$F" && grep -q 'snapshot restore' "$F" && grep -q '/opt/backup.db' "$F" && grep -q -- '--data-dir' "$F" && grep -q '/var/lib/etcd-restored' "$F"
