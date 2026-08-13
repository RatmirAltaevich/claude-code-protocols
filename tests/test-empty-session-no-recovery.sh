#!/usr/bin/env bash
# An empty session (clean git, no tracked files) must NOT produce recovery.json.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
git -C "$TMPDIR" init -q
git -C "$TMPDIR" config user.name "Continuity CI"
git -C "$TMPDIR" config user.email "ci@example.invalid"
git -C "$TMPDIR" commit --allow-empty -m "init" -q

# No tracked files, clean worktree.
HOOK_JSON='{"session_id":"empty-session"}'
printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

RECOVERY="$TMPDIR/.protocol/runtime/empty-session/recovery.json"
[ ! -f "$RECOVERY" ] || { echo "recovery.json was created for an empty session"; exit 1; }
