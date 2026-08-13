#!/usr/bin/env bash
# SessionStart hook — inject STATE.md and active changes as additionalContext.
# Exits silently if .protocol/ does not exist (project not initialized).

PROTOCOL_DIR=".protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

state=""
if [ -f "$PROTOCOL_DIR/STATE.md" ]; then
  state=$(cat "$PROTOCOL_DIR/STATE.md")
fi

active=""
if [ -d "$PROTOCOL_DIR/changes/active" ]; then
  for f in "$PROTOCOL_DIR/changes/active"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    content=$(cat "$f")
    active="${active}
### ${name}
${content}"
  done
fi

if [ -z "$state" ] && [ -z "$active" ]; then
  exit 0
fi

context="$state"
if [ -n "$active" ]; then
  context="${context}

## Active changes
${active}"
fi

python3 -c "
import sys, json
ctx = sys.stdin.read()
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'SessionStart',
    'additionalContext': ctx
  }
}))
" <<< "$context"
