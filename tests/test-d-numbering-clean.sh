#!/usr/bin/env bash
# Clean DECISIONS.md template must yield D-001 as first decision number.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cp "$REPO/plugin/templates/DECISIONS.md" "$TMPDIR/DECISIONS.md"

last_decision=$(
  grep -oE '^## D-[0-9]+' "$TMPDIR/DECISIONS.md" 2>/dev/null \
    | grep -oE 'D-[0-9]+' \
    | sort -V \
    | tail -1
) || true

if [ -z "$last_decision" ]; then
  next_decision="D-001"
else
  number=${last_decision#D-}
  next_decision=$(printf 'D-%03d' "$((10#$number + 1))")
fi

[ "$next_decision" = "D-001" ] || { echo "Expected D-001 on clean template, got $next_decision"; exit 1; }
