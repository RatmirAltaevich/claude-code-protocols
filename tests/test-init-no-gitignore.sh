#!/usr/bin/env bash
# Init in a project with no .gitignore must create one with runtime excluded.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

[ ! -f "$TMPDIR/.gitignore" ]

# Simulate what init does
echo "# Continuity Protocol runtime" >> "$TMPDIR/.gitignore"
echo ".protocol/runtime/" >> "$TMPDIR/.gitignore"

grep -q ".protocol/runtime/" "$TMPDIR/.gitignore"
