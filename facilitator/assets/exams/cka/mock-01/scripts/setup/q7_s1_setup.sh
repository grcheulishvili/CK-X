#!/bin/bash
kubectl create namespace web --dry-run=client -o yaml | kubectl apply -f -
