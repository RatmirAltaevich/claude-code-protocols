#!/usr/bin/env bash
# SessionEnd hook — writes a recovery snapshot and auto-updates mechanical
# STATE.md fields (Updated, Branch, Active change). Narrative sections
# (## Current, ## Blocked, ## Next) are never touched.
# Exits silently if .protocol/ does not exist.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

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
session_id="${session_id:-unknown}"

SESSION_DIR="$PROTOCOL_DIR/runtime/$session_id"

# If handoff already ran for this session, clean up and skip.
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

# Skip for sessions with no tracked work.
tracked_file="$SESSION_DIR/tracked-files.txt"
if [ "$dirty" = false ] && [ ! -s "$tracked_file" ]; then
  rm -rf "$SESSION_DIR"
  exit 0
fi

branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
commit=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Pass all values via env to avoid injection through paths or branch names with
# special characters (spaces, quotes, etc.).
CONTINUITY_PROJECT_DIR="$PROJECT_DIR" \
CONTINUITY_SESSION_DIR="$SESSION_DIR" \
CONTINUITY_SESSION_ID="$session_id" \
CONTINUITY_BRANCH="$branch" \
CONTINUITY_COMMIT="$commit" \
CONTINUITY_DIRTY="$dirty" \
python3 <<'PY'
import json, os, re, subprocess
from datetime import datetime, timezone
from pathlib import Path

project_dir = os.environ["CONTINUITY_PROJECT_DIR"]
session_dir = os.environ["CONTINUITY_SESSION_DIR"]
session_id  = os.environ["CONTINUITY_SESSION_ID"]
branch      = os.environ["CONTINUITY_BRANCH"]
commit      = os.environ["CONTINUITY_COMMIT"]
dirty       = json.loads(os.environ["CONTINUITY_DIRTY"])

tracked_path = os.path.join(session_dir, "tracked-files.txt")

try:
    result = subprocess.run(
        ["git", "-C", project_dir, "status", "--porcelain"],
        capture_output=True, text=True
    )
    git_files = [line[3:].strip() for line in result.stdout.splitlines() if line.strip()]
except Exception:
    git_files = []

runtime_files = []
if os.path.exists(tracked_path):
    with open(tracked_path) as f:
        runtime_files = [l.strip() for l in f if l.strip()]

all_modified = sorted(set(git_files + runtime_files))

changes_dir = os.path.join(project_dir, ".protocol", "changes", "active")
active_changes = []
if os.path.isdir(changes_dir):
    active_changes = sorted(
        fn[:-3] for fn in os.listdir(changes_dir)
        if fn.startswith("CHG-") and fn.endswith(".md")
    )

ended_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

snapshot = {
    "sessionId":     session_id,
    "endedAt":       ended_at,
    "branch":        branch,
    "commit":        commit,
    "dirty":         dirty,
    "modifiedFiles": all_modified,
    "activeChanges": active_changes,
}

with open(os.path.join(session_dir, "recovery.json"), "w") as f:
    json.dump(snapshot, f, indent=2)

# --- Auto-update mechanical STATE.md fields ---
# Only Updated, Branch, Active change are rewritten — purely from git/fs data.
# Narrative sections (## Current, ## Blocked, ## Next) are left untouched.
# The ⚠auto marker on Updated: signals the narrative may be stale.
# A full /continuity:protocol-handoff overwrites STATE.md and removes it.
state_path = Path(project_dir) / ".protocol" / "STATE.md"
if state_path.exists():
    today      = ended_at[:10]
    active_str = ", ".join(active_changes) if active_changes else "none"
    text = state_path.read_text(encoding="utf-8")
    text = re.sub(r"^Updated:.*$",       f"Updated: {today} ⚠auto",  text, flags=re.MULTILINE)
    text = re.sub(r"^Branch:.*$",        f"Branch: {branch}",             text, flags=re.MULTILINE)
    text = re.sub(r"^Active change:.*$", f"Active change: {active_str}",  text, flags=re.MULTILINE)
    state_path.write_text(text, encoding="utf-8")
PY
