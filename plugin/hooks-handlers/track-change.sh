#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — tracks modified files per session.
# Writes to .protocol/runtime/<session-id>/tracked-files.txt.
# Exits silently if .protocol/ does not exist.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

# Extract fields in separate calls to avoid read splitting on spaces in file paths.
file_path=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_input', {}).get('file_path', ''), end='')
except Exception:
    pass
" <<< "$input" 2>/dev/null)

# Validate session_id to prevent path traversal via crafted hook payloads.
session_id=$(python3 -c "
import sys, json, hashlib, re
try:
    d = json.loads(sys.stdin.read())
    raw = str(d.get('session_id', 'unknown'))
    if re.fullmatch(r'[A-Za-z0-9._-]{1,128}', raw):
        print(raw, end='')
    else:
        digest = hashlib.sha256(raw.encode()).hexdigest()[:16]
        print(f'invalid-{digest}', end='')
except Exception:
    print('unknown', end='')
" <<< "$input" 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0
fi

SESSION_DIR="$PROTOCOL_DIR/runtime/${session_id:-unknown}"
mkdir -p "$SESSION_DIR"

printf '%s\n' "$file_path" >> "$SESSION_DIR/tracked-files.txt"
sort -u "$SESSION_DIR/tracked-files.txt" -o "$SESSION_DIR/tracked-files.txt" 2>/dev/null || true
