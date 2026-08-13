#!/usr/bin/env bash
# Check shell syntax on all hook handlers.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for f in "$REPO/plugin/hooks-handlers/"*.sh; do
  bash -n "$f"
done
