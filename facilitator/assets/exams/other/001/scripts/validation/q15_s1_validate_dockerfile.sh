#!/bin/bash
# Q15 step 1: the Dockerfile at /tmp/exam/q15/Dockerfile has been optimized.
# Optimization signals (need most of them): alpine/slim base, package files copied
# before the rest of the source (cache-friendly ordering), and fewer separate layers
# than the original (original had 4 separate ENV lines and 4 separate RUN npm installs).

DF=/tmp/exam/q15/Dockerfile

if [ ! -f "$DF" ]; then
  echo "❌ Dockerfile not found at $DF"
  exit 1
fi

SCORE=0

# 1. Smaller base image (alpine or slim variant)
if grep -qiE "^FROM .*node.*(alpine|slim)" "$DF"; then
  SCORE=$((SCORE+1))
else
  echo "⚠️  Base image is not an alpine/slim variant (recommended for smaller size)"
fi

# 2. Cache-friendly ordering: package*.json copied before the full source copy
if grep -qiE "COPY .*package.*\.json" "$DF"; then
  SCORE=$((SCORE+1))
else
  echo "⚠️  package.json is not copied separately before the rest of the source (hurts layer caching)"
fi

# 3. Fewer ENV layers than the original (original had 4 separate ENV lines)
ENV_LINES=$(grep -ciE "^ENV " "$DF")
if [ "$ENV_LINES" -le 2 ]; then
  SCORE=$((SCORE+1))
else
  echo "⚠️  Too many separate ENV layers ($ENV_LINES); combine them to minimize layers"
fi

# 4. Fewer RUN layers than the original (original had 4 RUN instructions)
RUN_LINES=$(grep -ciE "^RUN " "$DF")
if [ "$RUN_LINES" -le 2 ]; then
  SCORE=$((SCORE+1))
else
  echo "⚠️  Too many separate RUN layers ($RUN_LINES); combine them to minimize layers"
fi

# Require at least 3 of the 4 optimization signals
if [ "$SCORE" -ge 3 ]; then
  echo "✅ Dockerfile is optimized (signals matched: $SCORE/4)"
  exit 0
else
  echo "❌ Dockerfile is not sufficiently optimized (signals matched: $SCORE/4)"
  exit 1
fi
