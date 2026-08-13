#!/usr/bin/env bash
# Two sessions must not share tracked-files.txt.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol"

# Simulate session A writing a file
SESSION_A="session-aaa"
SESSION_B="session-bbb"

mkdir -p "$TMPDIR/.protocol/runtime/$SESSION_A"
mkdir -p "$TMPDIR/.protocol/runtime/$SESSION_B"

echo "src/a.ts" >> "$TMPDIR/.protocol/runtime/$SESSION_A/tracked-files.txt"
echo "src/b.ts" >> "$TMPDIR/.protocol/runtime/$SESSION_B/tracked-files.txt"

# A must not see B's file and vice versa
grep -q "src/b.ts" "$TMPDIR/.protocol/runtime/$SESSION_A/tracked-files.txt" && exit 1
grep -q "src/a.ts" "$TMPDIR/.protocol/runtime/$SESSION_B/tracked-files.txt" && exit 1

exit 0
