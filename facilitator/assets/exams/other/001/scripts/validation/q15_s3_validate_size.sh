#!/bin/bash
# Q15 step 3: the optimized image exists and is smaller than the unoptimized base.
# Compare optimized-app:latest against node:14 (the original base). We avoid hardcoding
# byte counts: the optimized image (alpine-based, multi-stage) must be smaller than node:14.

IMG=optimized-app:latest

if ! docker image inspect "$IMG" &> /dev/null; then
  echo "❌ Image '$IMG' not found. Build it with: docker build -t $IMG ."
  exit 1
fi

OPT_SIZE=$(docker image inspect "$IMG" --format='{{.Size}}' 2>/dev/null)
if [ -z "$OPT_SIZE" ]; then
  echo "❌ Could not determine size of '$IMG'"
  exit 1
fi

# Reference size: pull node:14 size if available, else use a conservative threshold.
REF_SIZE=$(docker image inspect node:14 --format='{{.Size}}' 2>/dev/null)
if [ -z "$REF_SIZE" ]; then
  # node:14 (full) is ~900MB. Require the optimized image to be under 400MB as a proxy.
  THRESHOLD=$((400*1024*1024))
  if [ "$OPT_SIZE" -lt "$THRESHOLD" ]; then
    echo "✅ Image size is reduced ($((OPT_SIZE/1024/1024))MB, under 400MB threshold)"
    exit 0
  else
    echo "❌ Image is too large ($((OPT_SIZE/1024/1024))MB); expected a reduced (alpine/multi-stage) image"
    exit 1
  fi
fi

if [ "$OPT_SIZE" -lt "$REF_SIZE" ]; then
  echo "✅ Image size is reduced ($((OPT_SIZE/1024/1024))MB vs node:14 $((REF_SIZE/1024/1024))MB)"
  exit 0
else
  echo "❌ Image ($((OPT_SIZE/1024/1024))MB) is not smaller than the original base node:14 ($((REF_SIZE/1024/1024))MB)"
  exit 1
fi
