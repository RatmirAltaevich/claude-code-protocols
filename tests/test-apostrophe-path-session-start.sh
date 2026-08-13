#!/usr/bin/env bash
# session-start.sh must read recovery.json correctly when project path contains
# an apostrophe (single-quote), which previously broke direct Python path injection.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PROJ="$TMPDIR/project's files"
mkdir -p "$PROJ/.protocol/changes/active"
mkdir -p "$PROJ/.protocol/runtime/old-session"

cat > "$PROJ/.protocol/runtime/old-session/recovery.json" <<'JSON'
{
  "sessionId": "old-session",
  "endedAt": "2026-08-14T00:00:00Z",
  "branch": "main",
  "commit": "abc1234",
  "dirty": true,
  "modifiedFiles": ["src/app.py"],
  "activeChanges": ["CHG-001"]
}
JSON

output=$(
  CLAUDE_PROJECT_DIR="$PROJ" CLAUDE_SESSION_ID="new-session" \
    bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null
)

echo "$output" | grep -q "old-session" || {
  echo "Expected 'old-session' in SessionStart output for apostrophe path, got:"
  echo "$output"
  exit 1
}
