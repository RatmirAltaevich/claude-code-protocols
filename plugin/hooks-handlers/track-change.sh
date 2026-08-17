#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook — tracks modified files per session.
# Writes to .protocol/runtime/<session-id>/tracked-files.txt.
# Exits silently if .protocol/ does not exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

# Extracted in its own call so paths containing spaces or quotes stay intact.
file_path=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('tool_input', {}).get('file_path', ''), end='')
except Exception:
    pass
" <<< "$input" 2>/dev/null)

if [ -z "$file_path" ]; then
  exit 0
fi

session_id=$(printf '%s' "$input" | python3 "$SCRIPT_DIR/_session_id.py" 2>/dev/null)
SESSION_DIR="$PROTOCOL_DIR/runtime/${session_id:-unknown}"

mkdir -p "$SESSION_DIR" 2>/dev/null || exit 0

# Defence in depth: never write outside runtime/, whatever the id normalizer let through.
case "$(cd "$SESSION_DIR" 2>/dev/null && pwd -P)" in
  "$(cd "$PROTOCOL_DIR/runtime" 2>/dev/null && pwd -P)"/?*) ;;
  *) exit 0 ;;
esac

printf '%s\n' "$file_path" >> "$SESSION_DIR/tracked-files.txt"
sort -u "$SESSION_DIR/tracked-files.txt" -o "$SESSION_DIR/tracked-files.txt" 2>/dev/null || true
