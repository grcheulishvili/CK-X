#!/bin/bash
# Q15 step 2: a .dockerignore exists and excludes common unnecessary content.
DI=/tmp/exam/q15/.dockerignore

if [ ! -f "$DI" ]; then
  echo "❌ .dockerignore not found at $DI"
  exit 1
fi

# Should exclude at least node_modules and one of the noise file types created in setup
# (logs, markdown, tests, .git). Require node_modules + at least one more.
if ! grep -qiE "node_modules" "$DI"; then
  echo "❌ .dockerignore does not exclude node_modules"
  exit 1
fi

EXTRA=0
grep -qiE "(\.git|\*\.log|logs|\*\.md|tests|npm-debug)" "$DI" && EXTRA=1
if [ "$EXTRA" -ne 1 ]; then
  echo "❌ .dockerignore should also exclude other build noise (e.g. .git, *.log, *.md, tests)"
  exit 1
fi

echo "✅ .dockerignore exists and is properly configured"
exit 0
