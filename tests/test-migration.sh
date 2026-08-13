#!/usr/bin/env bash
# Verify that PROGRESS_LOG.md entries map to DECISIONS.md fields correctly.
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/PROGRESS_LOG.md" <<'EOF'
### Example decision (2026-08-01)
**Решение:** Use async queue.
**Причина:** Scale requirement.
**НЕ МЕНЯТЬ потому что:** Reverts scale gains.
EOF

# Migration logic: map fields
python3 - <<PYEOF
import re

content = open("$TMPDIR/PROGRESS_LOG.md").read()
decision = re.search(r'\*\*Решение:\*\* (.+)', content)
reason = re.search(r'\*\*Причина:\*\* (.+)', content)
no_change = re.search(r'\*\*НЕ МЕНЯТЬ потому что:\*\* (.+)', content)

assert decision, "Missing decision"
assert reason, "Missing reason"
assert no_change, "Missing no-change"

output = f"""## D-001 — Example decision

Status: Active
Date: 2026-08-01

### Decision

{decision.group(1)}

### Why

{reason.group(1)}

### Do not change because

{no_change.group(1)}
"""
open("$TMPDIR/DECISIONS.md", "w").write(output)
PYEOF

grep -q "### Decision" "$TMPDIR/DECISIONS.md"
grep -q "### Why" "$TMPDIR/DECISIONS.md"
grep -q "### Do not change because" "$TMPDIR/DECISIONS.md"
