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

# A new session starts (different session ID), delivered the way Claude Code
# delivers it: in the hook payload on stdin.
output=$(
  printf '{"hook_event_name":"SessionStart","session_id":"new-session"}' \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

# SessionStart must mention the crashed session.
echo "$output" | grep -q "crashed-session" || {
  echo "Expected 'crashed-session' in SessionStart output, got:"
  echo "$output"
  exit 1
}

# Warnings must stay bounded. Crashed sessions accumulate until runtime/ is
# cleaned, and a start banner of a dozen warnings just gets skimmed past.
for i in 1 2 3 4 5 6 7 8; do
  printf '{"tool_name":"Write","tool_input":{"file_path":"src/f%s.py"},"session_id":"stale-%s"}' "$i" "$i" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"
done

many=$(
  printf '{"hook_event_name":"SessionStart","session_id":"new-session"}' \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

warning_count=$(echo "$many" | grep -o "Aborted session:" | wc -l | tr -d ' ')
[ "$warning_count" -le 3 ] || {
  echo "Recovery warnings are not capped: $warning_count individual warnings emitted"
  exit 1
}

echo "$many" | grep -q "older session(s) with unreviewed runtime data" || {
  echo "Expected a summary line for the suppressed sessions, got:"
  echo "$many"
  exit 1
}
