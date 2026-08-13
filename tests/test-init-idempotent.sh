#!/usr/bin/env bash
# Re-running init must not duplicate the continuity block in CLAUDE.md.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/CLAUDE.md" <<'EOF'
# My Project

<!-- continuity:start -->
Project lifecycle is managed through `.protocol/`.
<!-- continuity:end -->

My custom rules.
EOF

# Count continuity markers — must remain exactly 1 after "re-init"
count=$(grep -c '<!-- continuity:start -->' "$TMPDIR/CLAUDE.md")
[ "$count" -eq 1 ] || { echo "Expected 1 marker, found $count"; exit 1; }
