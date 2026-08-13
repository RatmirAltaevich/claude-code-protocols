#!/usr/bin/env bash
# Smoke test: verify that .protocol/ structure is creatable in an empty dir.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Simulate what protocol-init does
mkdir -p "$TMPDIR/.protocol/changes/active"
mkdir -p "$TMPDIR/.protocol/changes/archive"
mkdir -p "$TMPDIR/.protocol/runtime"

[ -d "$TMPDIR/.protocol/changes/active" ]
[ -d "$TMPDIR/.protocol/changes/archive" ]
[ -d "$TMPDIR/.protocol/runtime" ]
