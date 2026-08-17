#!/usr/bin/env bash
# session-start.sh must normalize the payload session_id the same way the other
# hooks do, so the current session's own runtime directory is never reported as
# an aborted session.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"

RAW_ID="../../bad-session"

# Normalization is owned by _session_id.py — ask it, do not reimplement it here.
NORM_ID=$(printf '{"session_id":"%s"}' "../../bad-session" \
  | python3 "$REPO/plugin/hooks-handlers/_session_id.py")

# Simulate: the hooks wrote tracked-files.txt to the normalized directory.
mkdir -p "$TMPDIR/.protocol/runtime/$NORM_ID"
echo "src/app.py" > "$TMPDIR/.protocol/runtime/$NORM_ID/tracked-files.txt"

# Add STATE.md so session-start.sh emits output (needed to verify contents).
cat > "$TMPDIR/.protocol/STATE.md" <<'MD'
# Current state
Updated: 2026-08-14
Branch: main
MD

# The session id arrives in the payload on stdin — the same way Claude Code
# delivers it. There is no CLAUDE_SESSION_ID environment variable.
output=$(
  printf '{"hook_event_name":"SessionStart","session_id":"%s"}' "$RAW_ID" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

echo "$output" | grep -q "Current state" || {
  echo "Expected STATE.md content in session-start output"
  echo "Got: $output"
  exit 1
}

if echo "$output" | grep -q "Aborted session: $NORM_ID"; then
  echo "False recovery warning: current session '$NORM_ID' appeared as aborted"
  echo "Output:"
  echo "$output"
  exit 1
fi
