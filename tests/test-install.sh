#!/usr/bin/env bash
# Validate that all JSON files parse correctly.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -m json.tool "$REPO/.claude-plugin/marketplace.json" > /dev/null
python3 -m json.tool "$REPO/plugin/.claude-plugin/plugin.json" > /dev/null
python3 -m json.tool "$REPO/plugin/hooks/hooks.json" > /dev/null
