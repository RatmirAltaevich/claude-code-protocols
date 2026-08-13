#!/usr/bin/env bash
# SessionEnd hook — writes a recovery snapshot for crash recovery.
# Does NOT modify STATE.md, run tests, or archive changes.
# Exits silently if .protocol/ does not exist.

set -euo pipefail

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
" <<< "$input")
session_id="${session_id:-unknown}"

SESSION_DIR="$PROTOCOL_DIR/runtime/$session_id"

# If handoff already ran for this session, clean up and skip recovery.
if [ -f "$SESSION_DIR/handoff-complete" ]; then
  rm -rf "$SESSION_DIR"
  exit 0
fi

mkdir -p "$SESSION_DIR"

# Dirty = any tracked change (staged, unstaged, untracked)
if [ -n "$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)" ]; then
  dirty=true
else
  dirty=false
fi

branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
commit=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
ended_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Modified files: git status (staged + unstaged + untracked) + runtime tracked files
python3 - <<PYEOF
import json, subprocess, os

session_dir = "$SESSION_DIR"
project_dir = "$PROJECT_DIR"
tracked_path = os.path.join(session_dir, "tracked-files.txt")

# Files from git status --porcelain
try:
    result = subprocess.run(
        ["git", "-C", project_dir, "status", "--porcelain"],
        capture_output=True, text=True
    )
    git_files = [line[3:].strip() for line in result.stdout.splitlines() if line.strip()]
except Exception:
    git_files = []

# Files from runtime tracker
runtime_files = []
if os.path.exists(tracked_path):
    with open(tracked_path) as f:
        runtime_files = [l.strip() for l in f if l.strip()]

all_modified = sorted(set(git_files + runtime_files))

# Active changes
changes_dir = os.path.join(project_dir, ".protocol", "changes", "active")
active_changes = []
if os.path.isdir(changes_dir):
    active_changes = sorted(
        f[:-3] for f in os.listdir(changes_dir)
        if f.startswith("CHG-") and f.endswith(".md")
    )

snapshot = {
    "sessionId": "$session_id",
    "endedAt": "$ended_at",
    "branch": "$branch",
    "commit": "$commit",
    "dirty": json.loads("$dirty"),
    "modifiedFiles": all_modified,
    "activeChanges": active_changes,
}

with open(os.path.join(session_dir, "recovery.json"), "w") as f:
    json.dump(snapshot, f, indent=2)
PYEOF
