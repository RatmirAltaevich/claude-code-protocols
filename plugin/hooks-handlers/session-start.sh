#!/usr/bin/env bash
# SessionStart hook — inject STATE.md summary and active change headers as additionalContext.
# Exits silently if .protocol/ does not exist (project not initialized).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

# --- STATE.md (full) ---
state=""
if [ -f "$PROTOCOL_DIR/STATE.md" ]; then
  state=$(cat "$PROTOCOL_DIR/STATE.md")
fi

# --- Active changes: headers + metadata only, not full content ---
active_summary=""
if [ -d "$PROTOCOL_DIR/changes/active" ]; then
  for f in "$PROTOCOL_DIR/changes/active"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    # Extract frontmatter fields only (up to first blank line after ---)
    status=$(grep -m1 '^status:' "$f" | sed 's/status: *//')
    risk=$(grep -m1 '^risk:' "$f" | sed 's/risk: *//')
    title=$(grep -m1 '^# ' "$f" | sed 's/^# //')
    active_summary="${active_summary}
- ${name} — ${title}
  Status: ${status:-in-progress}
  Risk: ${risk:-unknown}"
  done
fi

# --- Recovery snapshots from other sessions ---
recovery_notice=""
if [ -d "$PROTOCOL_DIR/runtime" ]; then
  current_session="${CLAUDE_SESSION_ID:-}"
  for session_dir in "$PROTOCOL_DIR/runtime"/*/; do
    [ -d "$session_dir" ] || continue
    session_id=$(basename "$session_dir")
    [ "$session_id" = "$current_session" ] && continue
    if [ -f "$session_dir/recovery.json" ]; then
      modified=$(python3 -c "
import json, sys
try:
    d = json.load(open('$session_dir/recovery.json'))
    files = d.get('modifiedFiles', [])
    changes = d.get('activeChanges', [])
    print(f'session: {d.get(\"sessionId\", \"?\")}, modified files: {len(files)}, active changes: {\", \".join(changes) or \"none\"}')
except Exception:
    print('recovery.json found but unreadable')
" 2>/dev/null)
      recovery_notice="${recovery_notice}
⚠ Recovery snapshot found: ${modified}
  Review .protocol/runtime/${session_id}/recovery.json before starting unrelated work."
    elif [ -s "$session_dir/tracked-files.txt" ]; then
      file_count=$(wc -l < "$session_dir/tracked-files.txt" 2>/dev/null | tr -d ' ')
      recovery_notice="${recovery_notice}
⚠ Aborted session: ${session_id} — ${file_count} tracked file(s), SessionEnd did not run.
  Review .protocol/runtime/${session_id}/tracked-files.txt before continuing."
    fi
  done
fi

# --- Assemble context ---
if [ -z "$state" ] && [ -z "$active_summary" ] && [ -z "$recovery_notice" ]; then
  exit 0
fi

context="# Continuity context"

if [ -n "$state" ]; then
  context="${context}

## State

${state}"
fi

if [ -n "$active_summary" ]; then
  context="${context}

## Active changes
${active_summary}

Read the full CHANGE file only when working on that change."
fi

if [ -n "$recovery_notice" ]; then
  context="${context}
${recovery_notice}"
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
