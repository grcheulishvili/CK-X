#!/bin/bash
# Q16 step 1: Docker Content Trust is configured. DCT is controlled per-shell via the
# DOCKER_CONTENT_TRUST env var, so we accept evidence that it was enabled either in the
# current environment or recorded in the candidate's command file.
CMD_FILE=/tmp/exam/q16/dct-commands.sh

# Current environment (if the grader shell inherited it)
if [ "${DOCKER_CONTENT_TRUST:-0}" = "1" ]; then
  echo "✅ Docker Content Trust is enabled (DOCKER_CONTENT_TRUST=1)"
  exit 0
fi

# Recorded in the command file
if [ -f "$CMD_FILE" ] && grep -qE "export[[:space:]]+DOCKER_CONTENT_TRUST=1" "$CMD_FILE"; then
  echo "✅ Docker Content Trust enablement is documented (export DOCKER_CONTENT_TRUST=1)"
  exit 0
fi

echo "❌ Docker Content Trust is not enabled and not documented (expected export DOCKER_CONTENT_TRUST=1)"
exit 1
