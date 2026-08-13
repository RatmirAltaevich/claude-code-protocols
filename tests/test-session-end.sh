#!/usr/bin/env bash
# Test session-end.sh creates a valid recovery.json.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"

git -C "$TMPDIR" init -q
git -C "$TMPDIR" config user.name "Continuity CI"
git -C "$TMPDIR" config user.email "ci@example.invalid"
git -C "$TMPDIR" commit --allow-empty -m "init" -q

# Make worktree dirty so session-end.sh creates recovery.json
echo "test content" > "$TMPDIR/test.py"

HOOK_JSON='{"session_id":"test-session"}'

printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

RECOVERY="$TMPDIR/.protocol/runtime/test-session/recovery.json"
[ -f "$RECOVERY" ] || { echo "recovery.json not created"; exit 1; }

# Must be valid JSON
python3 -m json.tool "$RECOVERY" > /dev/null || { echo "recovery.json is not valid JSON"; exit 1; }

# Must contain required fields
python3 -c "
import json, sys
d = json.load(open('$RECOVERY'))
assert 'sessionId' in d, 'missing sessionId'
assert 'dirty' in d, 'missing dirty'
assert isinstance(d['dirty'], bool), 'dirty must be bool'
assert 'modifiedFiles' in d, 'missing modifiedFiles'
assert 'activeChanges' in d, 'missing activeChanges'
"
