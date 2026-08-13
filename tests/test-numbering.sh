#!/usr/bin/env bash
# Verify CHG numbering skips archived files correctly.
# After CHG-001.md is in archive/2026/, the next number must be CHG-002.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
mkdir -p "$TMPDIR/.protocol/changes/archive/2026"

# Simulate CHG-001 already archived
cat > "$TMPDIR/.protocol/changes/archive/2026/CHG-001.md" <<'EOF'
---
id: CHG-001
status: done
---
# Old change
EOF

# Run the numbering logic
last_change=$(
  find "$TMPDIR/.protocol/changes" -type f -name 'CHG-[0-9][0-9][0-9].md' 2>/dev/null \
    | grep -oE 'CHG-[0-9]+' \
    | sort -V \
    | tail -1
)

if [ -z "$last_change" ]; then
  next_change="CHG-001"
else
  number=${last_change#CHG-}
  next_change=$(printf 'CHG-%03d' "$((10#$number + 1))")
fi

[ "$next_change" = "CHG-002" ] || { echo "Expected CHG-002, got $next_change"; exit 1; }
