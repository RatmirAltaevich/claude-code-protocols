#!/usr/bin/env bash
# Regression: a session must never report itself as an aborted session.
#
# SessionStart fires again on /clear, resume and compact, by which time this
# session's own runtime directory already exists. If the hook cannot identify
# its own id, that directory looks foreign and every restart prints a false
# "SessionEnd did not run" warning about the session that is printing it.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
cat > "$TMPDIR/.protocol/STATE.md" <<'MD'
# Current state
Updated: 2026-08-17
Branch: main
MD

SESSION="6ec2eb28-1111-2222-3333-444455556666"

# This session edits a file: PostToolUse creates runtime/<session>/.
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py"},"session_id":"%s"}' "$SESSION" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"

[ -f "$TMPDIR/.protocol/runtime/$SESSION/tracked-files.txt" ] || {
  echo "setup failed: track-change.sh did not create the session runtime dir"
  exit 1
}

# SessionStart fires again for the SAME session (/clear, resume or compact).
output=$(
  printf '{"hook_event_name":"SessionStart","source":"compact","session_id":"%s"}' "$SESSION" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

echo "$output" | grep -q "Current state" || {
  echo "Expected STATE.md content in session-start output, got:"
  echo "$output"
  exit 1
}

if echo "$output" | grep -q "Aborted session"; then
  echo "FALSE ALARM: session warned about its own runtime directory"
  echo "$output"
  exit 1
fi

# A genuinely different session must still be reported.
other=$(
  printf '{"hook_event_name":"SessionStart","session_id":"a-different-session"}' \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)
echo "$other" | grep -q "Aborted session: $SESSION" || {
  echo "Expected a real aborted-session warning for a foreign session, got:"
  echo "$other"
  exit 1
}
