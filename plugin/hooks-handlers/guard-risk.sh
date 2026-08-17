#!/usr/bin/env bash
# PreToolUse(Write|Edit|NotebookEdit|Bash) hook — enforces risk.require_approval.
#
# Without this hook the approval rule lives only as prose inside a skill, which
# the model may or may not follow. Here it is a real interceptor: a matching
# tool call is escalated to the user via permissionDecision "ask", regardless of
# what the model decided.
#
# Emits nothing (and so takes no decision) unless a risk category matches.
# Exits silently if .protocol/ does not exist.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
PROTOCOL_DIR="$PROJECT_DIR/.protocol"

if [ ! -d "$PROTOCOL_DIR" ]; then
  exit 0
fi

input=$(cat)

session_id=$(printf '%s' "$input" | python3 "$SCRIPT_DIR/_session_id.py" 2>/dev/null || true)

CONTINUITY_PAYLOAD="$input" \
CONTINUITY_PROJECT_DIR="$PROJECT_DIR" \
CONTINUITY_SESSION_ID="${session_id:-unknown}" \
python3 <<'PY' 2>/dev/null || exit 0
import json
import os
import re
from pathlib import Path

project_dir = Path(os.environ["CONTINUITY_PROJECT_DIR"])
protocol    = project_dir / ".protocol"
session_id  = os.environ["CONTINUITY_SESSION_ID"]

try:
    payload = json.loads(os.environ["CONTINUITY_PAYLOAD"])
except Exception:
    raise SystemExit(0)

tool_name  = str(payload.get("tool_name", ""))
tool_input = payload.get("tool_input") or {}
if not isinstance(tool_input, dict):
    raise SystemExit(0)


# --- config ---------------------------------------------------------------
# Category names have been written several ways across config versions: as a
# YAML list of kebab-case names, and as a map of snake_case keys. Both still
# exist in the wild, and a name that fails to match silently disables that
# category's enforcement, so they are folded to one spelling here.
CATEGORY_ALIASES = {
    "database_migration": "data_migration",
    "db_migration": "data_migration",
    "migration": "data_migration",
    "migrations": "data_migration",
    "destructive_operation": "destructive_operations",
    "destructive": "destructive_operations",
    "secrets": "secrets_and_credentials",
    "credentials": "secrets_and_credentials",
    "secret_and_credentials": "secrets_and_credentials",
    "api": "public_api",
    "auth": "authentication",
    "authn": "authentication",
    "authz": "authorization",
    "payment": "payments",
}


def canonical(name):
    key = name.strip().strip("\"'").lower().replace("-", "_").replace(" ", "_")
    return CATEGORY_ALIASES.get(key, key)


# Deliberately a small line parser: the plugin must not depend on PyYAML being
# installed in whatever interpreter Claude Code happens to run.
def load_risk_config():
    enabled, enforcement = {}, "ask"
    try:
        lines = (protocol / "config.yaml").read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return enabled, enforcement
    in_risk = in_approval = False
    for line in lines:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        stripped = line.strip()
        if indent == 0:
            in_risk = stripped.startswith("risk:")
            in_approval = False
            continue
        if not in_risk:
            continue
        key, _, raw_value = stripped.partition(":")
        key, value = key.strip(), raw_value.split("#")[0].strip()
        if key == "require_approval":
            in_approval = True
            continue
        if key == "enforcement":
            enforcement = value.strip('"\'').lower() or "ask"
            in_approval = False
            continue
        if in_approval:
            if stripped.startswith("- "):
                enabled[canonical(stripped[2:])] = True       # list form
            elif value:
                enabled[canonical(key)] = value.lower() not in ("false", "no", "off", "0")
    return enabled, enforcement


# --- rules ----------------------------------------------------------------
# Path matching is token-based, not substring-based: "src/authService.ts"
# tokenizes to {src, auth, service, ts} and matches, while "AuthorProfile.tsx"
# tokenizes to {author, profile, tsx} and does not.
CATEGORY_RULES = {
    "authentication": {
        "tokens": {"auth", "login", "logout", "signin", "signup", "session",
                   "token", "tokens", "jwt", "oauth", "password", "passwd"},
    },
    "authorization": {
        "tokens": {"permission", "permissions", "role", "roles", "rbac", "acl",
                   "policy", "policies", "authz"},
    },
    "payments": {
        "tokens": {"payment", "payments", "billing", "invoice", "invoices",
                   "checkout", "charge", "charges", "refund", "refunds",
                   "subscription", "subscriptions", "stripe", "paypal",
                   "credit", "credits", "tariff", "tariffs", "pricing"},
    },
    "data_migration": {
        "tokens": {"migration", "migrations", "migrate", "alembic", "flyway", "liquibase"},
        "commands": [r"\balembic\s+(upgrade|downgrade)\b", r"\bprisma\s+migrate\b",
                     r"\bdrizzle-kit\b", r"\brails\s+db:migrate\b",
                     r"\bmanage\.py\s+migrate\b"],
    },
    "public_api": {
        "tokens": {"openapi", "swagger"},
        "paths": [r"(^|/)app/api/", r"(^|/)pages/api/"],
    },
    "production": {
        "tokens": {"prod", "production", "deploy", "deployment", "dockerfile", "terraform", "helm"},
        "paths": [r"(^|/)\.github/workflows/", r"(^|/)k8s/", r"docker-compose",
                  r"(^|/)vercel\.json$", r"(^|/)railway\.(json|toml)$"],
        "commands": [r"\bvercel\b[^|;]*--prod\b", r"\brailway\s+(up|down|redeploy)\b",
                     r"\bkubectl\s+(apply|delete)\b", r"\bterraform\s+(apply|destroy)\b",
                     r"\bfly\s+deploy\b", r"\bnpm\s+publish\b", r"\bdocker\s+push\b"],
    },
    "destructive_operations": {
        "commands": [r"\brm\s+-[a-zA-Z]*r", r"\bDROP\s+(TABLE|DATABASE|SCHEMA)\b",
                     r"\bTRUNCATE\s+", r"\bDELETE\s+FROM\b(?!.*\bWHERE\b)",
                     r"\bUPDATE\s+\S+\s+SET\b(?!.*\bWHERE\b)",
                     r"\bgit\s+push\b[^|;]*(--force\b|-f\b)", r"\bgit\s+reset\s+--hard\b",
                     r"\bgit\s+clean\s+-[a-zA-Z]*f", r"\bmkfs\b", r"\bdd\s+if="],
    },
    "secrets_and_credentials": {
        "tokens": {"secret", "secrets", "credential", "credentials", "keystore"},
        "paths": [r"(^|/)\.env(\.|$)", r"\.pem$", r"\.p12$", r"\.pfx$",
                  r"(^|/)id_rsa\b", r"\.key$"],
    },
}


def tokenize(path):
    # Split on separators and camelCase humps.
    spaced = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", path)
    return {t for t in re.split(r"[^A-Za-z0-9]+", spaced.lower()) if t}


def target_of(tool, data):
    if tool == "Bash":
        return "command", str(data.get("command", ""))
    for key in ("file_path", "notebook_path", "path"):
        if data.get(key):
            return "path", str(data[key])
    return None, ""


def relative(path):
    try:
        return str(Path(path).resolve().relative_to(project_dir.resolve()))
    except (ValueError, OSError):
        return path


def already_written(path):
    """A file recorded by PostToolUse was written once already this session.

    The write only happened because this hook let it through, so re-asking for
    every subsequent edit of the same file would be noise.
    """
    tracked = protocol / "runtime" / session_id / "tracked-files.txt"
    try:
        recorded = tracked.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return False
    return any(line.strip() and relative(line.strip()) == path for line in recorded)


def pinned_note(categories):
    """Surface an existing decision for the area, so the prompt carries the why."""
    try:
        text = (protocol / "DECISIONS.md").read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    hits = []
    for match in re.finditer(r"^## (D-\d+[^\n]*)\n(.*?)(?=^## D-|\Z)", text, re.MULTILINE | re.DOTALL):
        title, body = match.group(1).strip(), match.group(2)
        areas = re.search(r"^Areas: *(.+)$", body, re.MULTILINE)
        if not areas:
            continue
        listed = {a.strip().lower().replace("-", "_") for a in areas.group(1).split(",")}
        if listed & categories:
            reason = re.search(r"^### Do not change because\s*\n(.*?)(?=^### |\Z)",
                               body, re.MULTILINE | re.DOTALL)
            if reason and reason.group(1).strip():
                hits.append("{}: {}".format(title, " ".join(reason.group(1).split())))
    return "\n".join(hits[:3])


enabled, enforcement = load_risk_config()
if enforcement == "off":
    raise SystemExit(0)

kind, target = target_of(tool_name, tool_input)
if not target:
    raise SystemExit(0)

if kind == "path":
    target = relative(target)
    # The protocol's own bookkeeping is not project risk surface.
    if target.startswith(".protocol/") or target == ".protocol":
        raise SystemExit(0)

matched = set()
for category, rules in CATEGORY_RULES.items():
    if not enabled.get(category, False):
        continue
    if kind == "command":
        if any(re.search(p, target, re.IGNORECASE) for p in rules.get("commands", [])):
            matched.add(category)
    else:
        if tokenize(target) & rules.get("tokens", set()):
            matched.add(category)
        elif any(re.search(p, target, re.IGNORECASE) for p in rules.get("paths", [])):
            matched.add(category)

if not matched:
    raise SystemExit(0)

if kind == "path" and already_written(target):
    raise SystemExit(0)

areas = ", ".join(sorted(matched))
subject = "command" if kind == "command" else "file"
reason_parts = [
    "Continuity: this {subject} touches a risk area requiring approval ({areas}).".format(
        subject=subject, areas=areas
    ),
    "{}: {}".format("Command" if kind == "command" else "Target", target),
]

note = pinned_note(matched)
if note:
    reason_parts.append("Existing decisions for this area:\n" + note)

reason_parts.append(
    "Approve only if this was intended. Configured in .protocol/config.yaml "
    "(risk.require_approval); set risk.enforcement: off to disable."
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "\n".join(reason_parts),
    }
}))
PY
