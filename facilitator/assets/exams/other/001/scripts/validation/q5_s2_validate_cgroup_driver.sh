#!/bin/bash
# Step 2: the Docker daemon must still be running and responsive.
#
# This lab machine has no init system (dockerd is started directly), so
# `systemctl restart docker` is not available and switching the live daemon to the
# systemd cgroup driver would leave Docker down for the rest of the lab. The daemon
# config itself is graded in step 1; here we confirm the environment is still healthy.
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker CLI not found"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker daemon is not responding. If you restarted it, start it again with: dockerd &"
  exit 1
fi

echo "✅ Docker daemon is running and responsive"
exit 0
