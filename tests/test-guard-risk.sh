#!/usr/bin/env bash
# The risk-approval rule must be enforced by a real interceptor.
#
# Stating "requires approval before risky edits" in a skill is a request the
# model can decline. Only a PreToolUse hook returning permissionDecision can
# actually stop the call, so that behaviour is what is tested here.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$REPO/plugin/hooks-handlers/guard-risk.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.protocol/runtime"
cp "$REPO/plugin/templates/config.yaml" "$TMPDIR/.protocol/config.yaml"

# Emits the hook's decision, or "none" when it takes no decision.
decision() {
  local payload="$1"
  printf '%s' "$payload" \
    | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$GUARD" 2>/dev/null \
    | python3 -c "
import json, sys
raw = sys.stdin.read().strip()
if not raw:
    print('none')
else:
    print(json.loads(raw)['hookSpecificOutput']['permissionDecision'])
"
}

write_payload() {
  CONTINUITY_TEST_PATH="$1" python3 -c "
import json, os
print(json.dumps({
    'hook_event_name': 'PreToolUse',
    'session_id': 'guard-test',
    'tool_name': 'Write',
    'tool_input': {'file_path': os.environ['CONTINUITY_TEST_PATH'], 'content': 'x'},
}))
"
}

bash_payload() {
  CONTINUITY_TEST_CMD="$1" python3 -c "
import json, os
print(json.dumps({
    'hook_event_name': 'PreToolUse',
    'session_id': 'guard-test',
    'tool_name': 'Bash',
    'tool_input': {'command': os.environ['CONTINUITY_TEST_CMD']},
}))
"
}

expect() {
  local label="$1" want="$2" got="$3"
  [ "$got" = "$want" ] || { echo "$label: expected '$want', got '$got'"; exit 1; }
}

# --- risk areas are escalated -------------------------------------------------
expect "payments path" ask "$(decision "$(write_payload "$TMPDIR/src/payments/charge.ts")")"
expect "camelCase auth path" ask "$(decision "$(write_payload "$TMPDIR/src/authService.ts")")"
expect "dotenv file" ask "$(decision "$(write_payload "$TMPDIR/.env.production")")"
expect "migration dir" ask "$(decision "$(write_payload "$TMPDIR/db/migrations/003_add.sql")")"
expect "destructive command" ask "$(decision "$(bash_payload 'rm -rf ./build')")"
expect "force push" ask "$(decision "$(bash_payload 'git push --force origin main')")"

# --- ordinary work is left alone ---------------------------------------------
expect "plain component" none "$(decision "$(write_payload "$TMPDIR/src/components/Button.tsx")")"
expect "author is not auth" none "$(decision "$(write_payload "$TMPDIR/src/AuthorProfile.tsx")")"
expect "harmless command" none "$(decision "$(bash_payload 'npm run build')")"
expect "protocol bookkeeping" none "$(decision "$(write_payload "$TMPDIR/.protocol/STATE.md")")"

# --- approving once is enough for that file this session ----------------------
target="$TMPDIR/src/payments/charge.ts"
expect "first payments write" ask "$(decision "$(write_payload "$target")")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s"},"session_id":"guard-test"}' "$target" \
  | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$REPO/plugin/hooks-handlers/track-change.sh"
expect "second payments write" none "$(decision "$(write_payload "$target")")"

# --- a disabled category stops being enforced ---------------------------------
python3 - "$TMPDIR/.protocol/config.yaml" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(re.sub(r"^(\s*)payments: true", r"\1payments: false", text, flags=re.M))
PY
expect "payments disabled" none "$(decision "$(write_payload "$TMPDIR/src/payments/refund.ts")")"

# --- enforcement: off disables the whole guard --------------------------------
python3 - "$TMPDIR/.protocol/config.yaml" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
open(path, "w", encoding="utf-8").write(re.sub(r"^(\s*)enforcement: ask", r"\1enforcement: off", text, flags=re.M))
PY
expect "enforcement off" none "$(decision "$(bash_payload 'rm -rf ./build')")"

# --- legacy config shape must still enforce -----------------------------------
# Older configs list kebab-case category names instead of a snake_case map.
# A name that fails to match silently disables enforcement for that category,
# which is the worst possible failure mode for a guard.
cat > "$TMPDIR/.protocol/config.yaml" <<'YAML'
schema: 1
project: legacy-shape

risk:
  require_approval:
    - database-migration
    - authentication
    - payments
    - production
    - destructive-operation
    - railway-deploy
YAML

expect "legacy kebab payments"    ask "$(decision "$(write_payload "$TMPDIR/src/billing/invoice.ts")")"
expect "legacy kebab migration"   ask "$(decision "$(write_payload "$TMPDIR/db/migrations/004_x.sql")")"
expect "legacy kebab destructive" ask "$(decision "$(bash_payload 'rm -rf ./dist')")"
expect "legacy unknown category"  none "$(decision "$(write_payload "$TMPDIR/src/components/Card.tsx")")"

# --- no .protocol/ at all: never interfere ------------------------------------
# The guard exits before reading stdin here, so the writer takes SIGPIPE and
# pipefail would report the pipeline as failed. That is the test's plumbing,
# not the hook's behaviour.
BARE=$(mktemp -d)
out=$(printf '%s' "$(bash_payload 'rm -rf /')" | CLAUDE_PROJECT_DIR="$BARE" bash "$GUARD" 2>/dev/null || true)
rm -rf "$BARE"
[ -z "$out" ] || { echo "guard produced output in a project without .protocol/: $out"; exit 1; }
