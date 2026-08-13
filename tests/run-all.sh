#!/usr/bin/env bash
# Run all Continuity Protocol tests.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

run_test() {
  local name="$1"
  local script="$2"
  printf "  %-56s" "$name"
  if bash "$SCRIPT_DIR/$script" >/dev/null 2>&1; then
    echo "✓"
    PASS=$((PASS + 1))
  else
    echo "✗"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "Continuity Protocol — Test Suite"
echo "================================="
echo ""

echo "Install / JSON validation"
run_test "marketplace.json is valid JSON"              "test-install.sh"

echo ""
echo "Shell syntax"
run_test "hooks-handlers/*.sh syntax check"           "test-hooks.sh"

echo ""
echo "Init scenarios"
run_test "New empty project"                           "test-init.sh"
run_test "Existing CLAUDE.md — no overwrite"          "test-init-existing-claude.sh"
run_test "Idempotent re-run (STATE, DECISIONS, config)" "test-init-idempotent.sh"
run_test "No .gitignore"                              "test-init-no-gitignore.sh"
run_test "Path with spaces"                           "test-init-spaces.sh"

echo ""
echo "Numbering"
run_test "CHG-001 in archive → next is CHG-002"       "test-numbering.sh"
run_test "Clean DECISIONS.md → first decision is D-001" "test-d-numbering-clean.sh"

echo ""
echo "Real hook execution"
run_test "track-change.sh with space in file path"    "test-track-change.sh"
run_test "session-end.sh creates valid recovery.json" "test-session-end.sh"
run_test "SessionEnd skips recovery after handoff"    "test-handoff-marker.sh"

echo ""
echo "Runtime isolation"
run_test "Two sessions don't share tracked-files"     "test-runtime-isolation.sh"

echo ""
echo "Migration"
run_test "PROGRESS_LOG.md migration"                  "test-migration.sh"

echo ""
echo "---------------------------------"
echo "Passed: $PASS  Failed: $FAIL"
echo ""

[ "$FAIL" -eq 0 ]
