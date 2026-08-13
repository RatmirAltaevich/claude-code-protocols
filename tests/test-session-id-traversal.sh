#!/usr/bin/env bash
# A path-traversal session_id must never create files outside .protocol/runtime/.
# Without validation, {"session_id":"../../escaped"} would resolve to
# $PROJECT_DIR/escaped/ — outside the runtime directory.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
git -C "$TMPDIR" init -q
git -C "$TMPDIR" config user.name "Continuity CI"
git -C "$TMPDIR" config user.email "ci@example.invalid"
git -C "$TMPDIR" commit --allow-empty -m "init" -q

# Make worktree dirty so session-end.sh attempts to create a recovery file.
echo "dirty" > "$TMPDIR/test.py"

# Also verify track-change.sh is safe.
WRITE_JSON='{"tool_name":"Write","tool_input":{"file_path":"src/app.py"},"session_id":"../../escaped"}'
printf '%s' "$WRITE_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"

HOOK_JSON='{"session_id":"../../escaped"}'
printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-end.sh"

# Without validation, traversal would create $TMPDIR/escaped/
traversal_dir="$TMPDIR/escaped"
[ ! -d "$traversal_dir" ] || {
  echo "SECURITY: '$traversal_dir' was created via path traversal in session_id"
  exit 1
}

# All runtime files must be inside .protocol/runtime/
runtime_dir="$TMPDIR/.protocol/runtime"
if [ -d "$runtime_dir" ]; then
  while IFS= read -r -d '' path; do
    real=$(realpath "$path")
    real_runtime=$(realpath "$runtime_dir")
    case "$real" in
      "$real_runtime"/*) ;;
      *)
        echo "SECURITY: file outside runtime dir: $real"
        exit 1
        ;;
    esac
  done < <(find "$runtime_dir" -type f -print0 2>/dev/null)
fi
