#!/usr/bin/env bash
# session-end.sh must auto-update mechanical STATE.md fields (Updated, Branch,
# Active change) without touching narrative sections.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"

git -C "$TMPDIR" init -q
git -C "$TMPDIR" config user.name "Continuity CI"
git -C "$TMPDIR" config user.email "ci@example.invalid"
git -C "$TMPDIR" commit --allow-empty -m "init" -q

# STATE.md with old metadata and curated narrative
cat > "$TMPDIR/.protocol/STATE.md" <<'MD'
# Current state

Updated: 2020-01-01
Branch: old-branch
Active change: none
Last verified: abc1234 + clean worktree, 2020-01-01, passed

## Current

Old narrative that must not be touched.

## In progress

none

## Blocked

none

## Next

Do the thing.
MD

# Dirty worktree so session-end.sh doesn't exit early
echo "test" > "$TMPDIR/test.py"

HOOK_JSON='{"session_id":"test-session"}'
printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

STATE="$TMPDIR/.protocol/STATE.md"

today=$(date -u +"%Y-%m-%d")

# Updated field must show today's date with ⚠auto marker
grep -q "Updated: $today ⚠auto" "$STATE" || {
  echo "Expected 'Updated: $today ⚠auto' in STATE.md"
  grep "Updated:" "$STATE" || echo "(Updated: line not found)"
  exit 1
}

# Old date must be gone from Updated line
grep "^Updated:" "$STATE" | grep -q "2020-01-01" && {
  echo "Old date still present in Updated: field"
  exit 1
} || true

# Narrative section must be untouched
grep -q "Old narrative that must not be touched." "$STATE" || {
  echo "Narrative section was modified"
  exit 1
}

# Last verified must be untouched (session-end doesn't run tests)
grep -q "Last verified: abc1234" "$STATE" || {
  echo "Last verified was modified — session-end must not touch it"
  exit 1
}
