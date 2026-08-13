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

# Extract file_path and session_id from hook input JSON
read -r file_path session_id <<< "$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    fp = d.get('tool_input', {}).get('file_path', '')
    sid = d.get('session_id', 'unknown')
    print(fp, sid)
except Exception:
    print('', 'unknown')
" <<< "$input" 2>/dev/null)"

if [ -z "$file_path" ]; then
  exit 0
fi

SESSION_DIR="$PROTOCOL_DIR/runtime/${session_id:-unknown}"
mkdir -p "$SESSION_DIR"

printf '%s\n' "$file_path" >> "$SESSION_DIR/tracked-files.txt"
sort -u "$SESSION_DIR/tracked-files.txt" -o "$SESSION_DIR/tracked-files.txt" 2>/dev/null || true
