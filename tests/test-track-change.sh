#!/usr/bin/env bash
# Test track-change.sh with real JSON input including a path with spaces.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol"

# Simulate hook input JSON — file path contains a space
HOOK_JSON='{"session_id":"session-abc","tool_input":{"file_path":"src/my file.ts"}}'

printf '%s' "$HOOK_JSON" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"

TRACKED="$TMPDIR/.protocol/runtime/session-abc/tracked-files.txt"
[ -f "$TRACKED" ] || { echo "tracked-files.txt not created"; exit 1; }

content=$(cat "$TRACKED")
[ "$content" = "src/my file.ts" ] || { echo "Expected 'src/my file.ts', got: $content"; exit 1; }
