#!/usr/bin/env bash
# session-end.sh must work when the project path contains spaces and double quotes.
# This verifies the env-var approach (Fix 5) prevents shell injection.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Project dir with both a space and a double quote in its name.
PROJ="$TMPDIR/my project\"s dir"
mkdir -p "$PROJ/.protocol/changes/active"
git -C "$PROJ" init -q
git -C "$PROJ" config user.name "Continuity CI"
git -C "$PROJ" config user.email "ci@example.invalid"
git -C "$PROJ" commit --allow-empty -m "init" -q

# Make worktree dirty so recovery.json is created.
echo "test" > "$PROJ/test.py"

HOOK_JSON='{"session_id":"test-session"}'
printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$PROJ" bash "$REPO/plugin/hooks-handlers/session-end.sh"

RECOVERY="$PROJ/.protocol/runtime/test-session/recovery.json"
[ -f "$RECOVERY" ] || { echo "recovery.json not created for path with special chars"; exit 1; }
python3 -m json.tool "$RECOVERY" > /dev/null || { echo "recovery.json is not valid JSON"; exit 1; }
