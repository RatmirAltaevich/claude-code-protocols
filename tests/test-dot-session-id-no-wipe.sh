#!/usr/bin/env bash
# A session_id of "." or ".." must never let SessionEnd delete .protocol/.
#
# Both consist only of characters a naive [A-Za-z0-9._-] check permits, yet
# .protocol/runtime/.. resolves to .protocol itself. session-end.sh calls
# `rm -rf` on that directory, and it resolves the path first — so unlike a
# literal "dir/..", which rm refuses, the resolved form deletes for real.
#
# Both branches that reach the removal are exercised:
#   1. a session that ends with no tracked work
#   2. a session whose handoff-complete marker is already present
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Worktree must be CLEAN for the "no tracked work" branch to be reached,
# so everything is committed during setup.
setup_project() {
  local dir="$1"
  mkdir -p "$dir/.protocol/changes/active" "$dir/.protocol/runtime"
  echo "# Current state" > "$dir/.protocol/STATE.md"
  echo "# Decisions"     > "$dir/.protocol/DECISIONS.md"
  git -C "$dir" init -q
  git -C "$dir" config user.name "Continuity CI"
  git -C "$dir" config user.email "ci@example.invalid"
  git -C "$dir" add -A
  git -C "$dir" commit -m "init" -q
  [ -z "$(git -C "$dir" status --porcelain)" ] || {
    echo "setup failed: worktree is dirty, the removal branch would be skipped"
    exit 1
  }
}

assert_intact() {
  local dir="$1" label="$2"
  for required in "$dir/.protocol" "$dir/.protocol/STATE.md" "$dir/.protocol/DECISIONS.md"; do
    [ -e "$required" ] || {
      echo "SECURITY [$label]: $required was destroyed"
      exit 1
    }
  done
}

for bad_id in ".." "." "..."; do
  # --- branch 1: session ends with no tracked work ---
  TMPDIR=$(mktemp -d)
  setup_project "$TMPDIR"
  printf '{"hook_event_name":"SessionEnd","session_id":"%s"}' "$bad_id" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"
  assert_intact "$TMPDIR" "no-tracked-work id=$bad_id"
  rm -rf "$TMPDIR"

  # --- branch 2: a handoff marker sits at the traversed location ---
  TMPDIR=$(mktemp -d)
  setup_project "$TMPDIR"
  touch "$TMPDIR/.protocol/handoff-complete"
  printf '{"hook_event_name":"SessionEnd","session_id":"%s"}' "$bad_id" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"
  assert_intact "$TMPDIR" "handoff-marker id=$bad_id"
  rm -rf "$TMPDIR"
done

# Runtime bookkeeping must also stay inside runtime/ — a traversing id must not
# scatter recovery.json or tracked-files.txt into .protocol/ itself, where they
# are not gitignored and would be committed.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
setup_project "$TMPDIR"
echo "dirty" > "$TMPDIR/untracked.txt"   # force a recovery snapshot to be written

printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py"},"session_id":".."}' \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"
printf '{"hook_event_name":"SessionEnd","session_id":".."}' \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

for stray in "$TMPDIR/.protocol/recovery.json" "$TMPDIR/.protocol/tracked-files.txt"; do
  [ ! -e "$stray" ] || {
    echo "SECURITY: runtime file escaped into .protocol/: $stray"
    exit 1
  }
done
