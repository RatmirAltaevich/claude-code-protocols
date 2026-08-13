#!/usr/bin/env bash
# After handoff writes handoff-complete, SessionEnd must NOT create recovery.json.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"

git -C "$TMPDIR" init -q
git -C "$TMPDIR" commit --allow-empty -m "init" -q

SESSION_DIR="$TMPDIR/.protocol/runtime/test-session"
mkdir -p "$SESSION_DIR"
touch "$SESSION_DIR/handoff-complete"

HOOK_JSON='{"session_id":"test-session"}'

printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

# Session dir should be cleaned up, recovery.json must NOT exist
[ ! -f "$SESSION_DIR/recovery.json" ] || { echo "recovery.json was created despite handoff-complete"; exit 1; }
