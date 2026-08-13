#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — appends modified file paths to .protocol/runtime/tracked_files.txt.
# Used by protocol-handoff to know what was touched this session.

PROTOCOL_DIR=".protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

file_path=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    pass
" <<< "$input" 2>/dev/null)

if [ -n "$file_path" ]; then
  mkdir -p "$PROTOCOL_DIR/runtime"
  echo "$file_path" >> "$PROTOCOL_DIR/runtime/tracked_files.txt"
fi
