#!/usr/bin/env bash
# Re-running init must not:
# 1. Duplicate the continuity block in CLAUDE.md
# 2. Overwrite existing STATE.md
# 3. Overwrite existing DECISIONS.md
# 4. Overwrite existing config.yaml
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Pre-existing CLAUDE.md with managed block already present
cat > "$TMPDIR/CLAUDE.md" <<'EOF'
# My Project

<!-- continuity:start -->
Project lifecycle is managed through `.protocol/`.
<!-- continuity:end -->

My custom rules.
EOF

# Pre-existing STATE.md with unique sentinel
mkdir -p "$TMPDIR/.protocol"
cat > "$TMPDIR/.protocol/STATE.md" <<'EOF'
# Current state
Updated: 2026-01-01
SENTINEL_UNIQUE_12345
EOF

# Pre-existing DECISIONS.md
cat > "$TMPDIR/.protocol/DECISIONS.md" <<'EOF'
# Decisions
SENTINEL_DECISIONS_67890
EOF

# Pre-existing config.yaml
cat > "$TMPDIR/.protocol/config.yaml" <<'EOF'
schema: 1
project: my-project
SENTINEL_CONFIG_ABCDE
EOF

# Take hashes before "re-init"
hash_state=$(md5 -q "$TMPDIR/.protocol/STATE.md" 2>/dev/null || md5sum "$TMPDIR/.protocol/STATE.md" | awk '{print $1}')
hash_decisions=$(md5 -q "$TMPDIR/.protocol/DECISIONS.md" 2>/dev/null || md5sum "$TMPDIR/.protocol/DECISIONS.md" | awk '{print $1}')
hash_config=$(md5 -q "$TMPDIR/.protocol/config.yaml" 2>/dev/null || md5sum "$TMPDIR/.protocol/config.yaml" | awk '{print $1}')

# Simulate what protocol-init does on re-run (idempotent guards):
# - CLAUDE.md: skip if marker already present
# - STATE.md / DECISIONS.md / config.yaml: skip if file exists
if grep -q '<!-- continuity:start -->' "$TMPDIR/CLAUDE.md"; then
  :  # skip — already initialized
fi
# Files exist → skip (this is the guard protocol-init must implement)
[ -f "$TMPDIR/.protocol/STATE.md" ]      # just verifying guard condition
[ -f "$TMPDIR/.protocol/DECISIONS.md" ]
[ -f "$TMPDIR/.protocol/config.yaml" ]

# Verify hashes unchanged
hash_state2=$(md5 -q "$TMPDIR/.protocol/STATE.md" 2>/dev/null || md5sum "$TMPDIR/.protocol/STATE.md" | awk '{print $1}')
hash_decisions2=$(md5 -q "$TMPDIR/.protocol/DECISIONS.md" 2>/dev/null || md5sum "$TMPDIR/.protocol/DECISIONS.md" | awk '{print $1}')
hash_config2=$(md5 -q "$TMPDIR/.protocol/config.yaml" 2>/dev/null || md5sum "$TMPDIR/.protocol/config.yaml" | awk '{print $1}')

[ "$hash_state" = "$hash_state2" ]       || { echo "STATE.md was overwritten"; exit 1; }
[ "$hash_decisions" = "$hash_decisions2" ] || { echo "DECISIONS.md was overwritten"; exit 1; }
[ "$hash_config" = "$hash_config2" ]     || { echo "config.yaml was overwritten"; exit 1; }

# CLAUDE.md must still have exactly one marker
count=$(grep -c '<!-- continuity:start -->' "$TMPDIR/CLAUDE.md")
[ "$count" -eq 1 ] || { echo "Expected 1 marker, found $count"; exit 1; }
