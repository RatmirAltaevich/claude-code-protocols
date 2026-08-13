#!/usr/bin/env bash
# Crash recovery: an aborted session (track-change ran, session-end did not)
# must appear as a warning in the next session's SessionStart output.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
git -C "$TMPDIR" init -q
git -C "$TMPDIR" config user.name "Continuity CI"
git -C "$TMPDIR" config user.email "ci@example.invalid"
git -C "$TMPDIR" commit --allow-empty -m "init" -q

# Simulate a crash: track-change runs, session-end never fires.
WRITE_JSON='{"tool_name":"Write","tool_input":{"file_path":"src/app.py"},"session_id":"crashed-session"}'
printf '%s' "$WRITE_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"

# A new session starts (different session ID).
output=$(
  CLAUDE_PROJECT_DIR="$TMPDIR" CLAUDE_SESSION_ID="new-session" \
    bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

# SessionStart must mention the crashed session.
echo "$output" | grep -q "crashed-session" || {
  echo "Expected 'crashed-session' in SessionStart output, got:"
  echo "$output"
  exit 1
}
