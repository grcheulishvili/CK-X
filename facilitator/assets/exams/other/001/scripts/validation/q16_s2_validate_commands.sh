#!/bin/bash
# Q16 step 2: the command file exists and contains the required DCT workflow steps.
CMD_FILE=/tmp/exam/q16/dct-commands.sh

if [ ! -f "$CMD_FILE" ]; then
  echo "❌ Command file not found at $CMD_FILE"
  exit 1
fi

check() {
  if grep -qE "$1" "$CMD_FILE"; then
    return 0
  else
    echo "❌ Command file missing step: $2"
    return 1
  fi
}

FAIL=0
check "DOCKER_CONTENT_TRUST=1"                         "enable Docker Content Trust"            || FAIL=1
check "docker[[:space:]]+pull[[:space:]]+.*alpine"     "pull the signed alpine image"           || FAIL=1
check "DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE|PASSPHRASE" "configure a signing passphrase"  || FAIL=1
check "docker[[:space:]]+build[[:space:]]+.*localhost:5000" "build image for the local registry" || FAIL=1
check "docker[[:space:]]+push[[:space:]]+.*localhost:5000" "push (and sign) image to local registry" || FAIL=1

if [ "$FAIL" -eq 0 ]; then
  echo "✅ Command file exists with correct DCT commands"
  exit 0
fi
exit 1
