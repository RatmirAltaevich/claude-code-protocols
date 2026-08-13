#!/usr/bin/env bash
# session-start.sh must normalize CLAUDE_SESSION_ID before comparing with
# runtime directory names, preventing a false "aborted session" warning for
# the current session when its ID contains non-standard characters.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"

RAW_ID="../../bad-session"

# Compute the normalized form (same algorithm as hooks).
NORM_ID=$(python3 -c "
import hashlib, re, sys
raw = sys.argv[1]
if re.fullmatch(r'[A-Za-z0-9._-]{1,128}', raw):
    print(raw, end='')
else:
    d = hashlib.sha256(raw.encode()).hexdigest()[:16]
    print(f'invalid-{d}', end='')
" "$RAW_ID")

# Simulate: hooks wrote tracked-files.txt to the normalized directory.
mkdir -p "$TMPDIR/.protocol/runtime/$NORM_ID"
echo "src/app.py" > "$TMPDIR/.protocol/runtime/$NORM_ID/tracked-files.txt"

# Add STATE.md so session-start.sh emits output (needed to verify contents).
cat > "$TMPDIR/.protocol/STATE.md" <<'MD'
# Current state
Updated: 2026-08-14
Branch: main
MD

output=$(
  CLAUDE_PROJECT_DIR="$TMPDIR" CLAUDE_SESSION_ID="$RAW_ID" \
    bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

# Confirm output is non-empty (STATE.md must appear).
echo "$output" | grep -q "Current state" || {
  echo "Expected STATE.md content in session-start output"
  echo "Got: $output"
  exit 1
}

# The current session's directory must NOT appear as an aborted-session warning.
if echo "$output" | grep -q "Aborted session: $NORM_ID"; then
  echo "False recovery warning: current session '$NORM_ID' appeared as aborted"
  echo "Output:"
  echo "$output"
  exit 1
fi
