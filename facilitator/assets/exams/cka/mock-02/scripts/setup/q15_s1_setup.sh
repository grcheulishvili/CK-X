#!/bin/bash
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
