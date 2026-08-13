#!/usr/bin/env bash
# Init must work in a path that contains spaces.
set -euo pipefail

TMPDIR=$(mktemp -d)
SPACED="$TMPDIR/my project dir"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$SPACED"
mkdir -p "$SPACED/.protocol/changes/active"
mkdir -p "$SPACED/.protocol/changes/archive"
mkdir -p "$SPACED/.protocol/runtime"

[ -d "$SPACED/.protocol/changes/active" ]
