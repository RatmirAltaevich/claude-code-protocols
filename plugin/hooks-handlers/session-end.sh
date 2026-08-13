#!/usr/bin/env bash
# SessionEnd hook — writes a recovery snapshot for crash recovery.
# Does NOT modify STATE.md, run tests, or archive changes.
# Exits silently if .protocol/ does not exist.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

session_id=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('session_id', 'unknown'))
except Exception:
    print('unknown')
" <<< "$input" 2>/dev/null)
session_id="${session_id:-unknown}"

SESSION_DIR="$PROTOCOL_DIR/runtime/$session_id"
mkdir -p "$SESSION_DIR"

# Gather git state
branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
commit=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
dirty=$(git -C "$PROJECT_DIR" diff --quiet 2>/dev/null && echo false || echo true)

# Modified files from git + tracked runtime files
git_modified=$(git -C "$PROJECT_DIR" diff --name-only HEAD 2>/dev/null | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip().splitlines()))")
tracked_file="$SESSION_DIR/tracked-files.txt"
if [ -f "$tracked_file" ]; then
  runtime_modified=$(python3 -c "import json; lines=[l.strip() for l in open('$tracked_file') if l.strip()]; print(json.dumps(lines))")
else
  runtime_modified="[]"
fi

# Active changes
active_changes=$(
  find "$PROTOCOL_DIR/changes/active" -name 'CHG-*.md' 2>/dev/null \
    | xargs -I{} basename {} .md \
    | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip().splitlines()))"
)

ended_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

python3 -c "
import json, sys

session_id = '$session_id'
ended_at = '$ended_at'
branch = '$branch'
commit = '$commit'
dirty = $dirty

git_modified = $git_modified
runtime_modified = $runtime_modified
active_changes = $active_changes

all_modified = sorted(set(git_modified + runtime_modified))

snapshot = {
    'sessionId': session_id,
    'endedAt': ended_at,
    'branch': branch,
    'commit': commit,
    'dirty': dirty,
    'modifiedFiles': all_modified,
    'activeChanges': active_changes
}

with open('$SESSION_DIR/recovery.json', 'w') as f:
    json.dump(snapshot, f, indent=2)
" 2>/dev/null || true
