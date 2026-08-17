#!/usr/bin/env bash
# The "do not change, and why" constraints must reach the session context.
#
# This is the payload the whole protocol exists to deliver. Injecting only
# branch and commit — which git already answers — while leaving the constraints
# in a file means they apply only when the model happens to open that file.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/changes/active"
echo "# Current state" > "$TMPDIR/.protocol/STATE.md"

cat > "$TMPDIR/.protocol/DECISIONS.md" <<'MD'
# Decisions

## PINNED

| ID | Decision | Area | Related code |
|---|---|---|---|
| D-001 | Generation stays synchronous | payments | `src/generation/service.ts` |

---

## Entries

## D-001 — keep generation synchronous

Status: Active
Date: 2026-07-31
Areas: payments
Related code: `src/generation/service.ts`

### Decision

Generation calls are synchronous.

### Do not change because

Duplicate orders reappear. Incident log 2026-07-01, 2026-07-14.

## D-002 — retired approach

Status: Retired
Date: 2026-06-01
Areas: payments

### Do not change because

This one is retired and must not be injected.
MD

context=$(
  printf '{"hook_event_name":"SessionStart","session_id":"decisions-test"}' \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null \
    | python3 -c "
import json, sys
print(json.load(sys.stdin)['hookSpecificOutput']['additionalContext'])
"
)

echo "$context" | grep -q "Duplicate orders reappear" || {
  echo "Active 'Do not change because' text never reached the context:"
  echo "$context"
  exit 1
}

echo "$context" | grep -q "D-001" || {
  echo "PINNED entry missing from context"
  exit 1
}

if echo "$context" | grep -q "This one is retired"; then
  echo "Retired decision was injected — only Active entries belong in context"
  exit 1
fi

# Template examples live in HTML comments and must not be presented as real rules.
cp "$REPO/plugin/templates/DECISIONS.md" "$TMPDIR/.protocol/DECISIONS.md"
template_context=$(
  printf '{"hook_event_name":"SessionStart","session_id":"decisions-test"}' \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/session-start.sh" 2>/dev/null \
    | python3 -c "
import json, sys
print(json.load(sys.stdin)['hookSpecificOutput']['additionalContext'])
"
)
if echo "$template_context" | grep -q "Duplicate orders reappear"; then
  echo "Commented-out template example was injected as a real constraint"
  exit 1
fi
