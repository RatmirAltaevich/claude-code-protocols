---
name: protocol-work
description: Manage a non-trivial code change using adaptive planning, relevant decisions, implementation and verification. Use when implementing features, fixes, refactoring or integrations.
---

# Protocol Work

Adaptive work cycle. Classifies the task, applies the right amount of process, implements, verifies.

Invoke this skill at the start of any non-trivial task. For obvious one-liner fixes, work directly — this skill adds overhead only when it reduces risk.

---

## Step 1 — Load context

Read in parallel:
1. `.protocol/STATE.md` — current project state
2. PINNED table in `.protocol/DECISIONS.md` — critical decisions at a glance
3. `.protocol/changes/active/` — any open CHANGEs

```bash
cat .protocol/STATE.md 2>/dev/null
# Extract only the PINNED table from DECISIONS.md
sed -n '/^## PINNED/,/^---/p' .protocol/DECISIONS.md 2>/dev/null
ls .protocol/changes/active/ 2>/dev/null
```

Do not load full DECISIONS.md entries at this point — load only what is relevant in Step 4.

---

## Step 2 — Classify the task

Evaluate the user's request against these criteria:

| Type | Conditions | Process |
|------|-----------|---------|
| **Small** | 1–2 files, no behavior change, no risk area affected | Execute directly — no CHANGE.md |
| **Standard** | Multiple files, new behavior, or new public surface | Create CHANGE.md, proceed |
| **High-risk** | Task semantically affects any enabled risk category | CHANGE.md + **stop for plan approval** |
| **Epic** | New subsystem or major integration (>5 files, >1 week) | Extended CHANGE.md + approval |

**Risk categories** (from `.protocol/config.yaml risk.require_approval`):

| Category | Examples |
|---|---|
| `authentication` | login, registration, session management, token validation |
| `authorization` | permission checks, role enforcement, access control |
| `payments` | charging, refunding, crediting, billing logic |
| `data_migration` | schema changes, column additions/removals, data backfills |
| `public_api` | adding, removing, or changing externally-visible endpoints |
| `production` | deploying to prod, changing prod configuration |
| `destructive_operations` | deleting data, dropping tables, irreversible writes |
| `secrets_and_credentials` | working with API keys, tokens, passwords, env vars |

**Do not rely on literal keyword matching.** Evaluate semantics: a task about "user login" affects `authentication` even if no keyword appears in the request.

Your classification here is the primary control, but it is not the only one: the
`PreToolUse` hook independently escalates tool calls that match a risk category
to the user. Expect an approval prompt on those calls even when you judged the
task Small — that is the hook working, not an error. The hook matches paths and
commands mechanically, so it catches less than you can; never treat "the hook
did not stop me" as evidence a change is low-risk.

If the user has already explicitly approved a specific change and its consequences, do not re-request approval. Record the approval in CHANGE.md:

```yaml
approval:
  required: true
  status: approved
  approved_at: YYYY-MM-DD
```

If unsure between Small and Standard: choose Standard.

---

## Step 3a — Small task

Execute directly. No CHANGE.md.

After completion: if a non-obvious architectural choice was made, note it briefly so `protocol-handoff` can capture it in DECISIONS.md.

---

## Step 3b — Standard task

Determine the next change number:

```bash
last_change=$(
  find .protocol/changes -type f -name 'CHG-[0-9][0-9][0-9].md' 2>/dev/null \
    | grep -oE 'CHG-[0-9]+' \
    | sort -V \
    | tail -1
) || true

if [ -z "$last_change" ]; then
  next_change="CHG-001"
else
  number=${last_change#CHG-}
  next_change=$(printf 'CHG-%03d' "$((10#$number + 1))")
fi
```

This searches both `active/` and `archive/` recursively, so CHG numbers never reset after archiving.

Copy `${CLAUDE_PLUGIN_ROOT}/templates/CHANGE.md` to `.protocol/changes/active/<next_change>.md`.
Fill in the `id`, `created`, and all sections. Fill `Verification` from `.protocol/config.yaml commands`.
Do not reproduce the template inline — use the file.

Show the CHANGE.md to the user and proceed to implementation. No need to wait for explicit approval on Standard tasks.

---

## Step 3c — High-risk task

Create CHANGE.md with `size: high-risk` and **stop**.

Present the plan to the user:
- What will change specifically (files, functions, data)
- Rollback procedure
- Verification commands to confirm success

Wait for explicit user approval before making any changes to the codebase.
Record approval in the CHANGE.md `approval` field when granted.

---

## Step 4 — Consult decisions before implementing

Using the PINNED table from Step 1, identify which entries are relevant to this task.
Load full text only for those entries:

```bash
# Example: load full text of D-003 from DECISIONS.md
sed -n '/^## D-003/,/^## D-/p' .protocol/DECISIONS.md | head -50
```

Before changing any of the following, check for a relevant DECISIONS entry:

- Architectural approach (provider, model, framework choice)
- Authentication or authorization logic
- Payment or credit handling
- Database schema or migration
- Public API surface
- Async vs sync handling
- Dependency versions

If a decision says "Do not change because" and the task conflicts: surface the conflict to the user. Do not silently work around it.

---

## Step 5 — Code navigation

Use in this priority order:

1. **codebase-memory-mcp** — if `navigation.provider` is `auto` or `codebase-memory`, and the project is indexed:
   - `search_graph(name_pattern="...")` to find functions/classes
   - `get_code_snippet(qualified_name="...")` for exact source
   - `trace_path(function_name="...", direction="inbound|outbound")`

2. **Language server / LSP** — if available in the environment

3. **rg + targeted reads** — fallback, always works:
   - `rg -n "function_name"` to locate
   - `Read` the file with `offset`/`limit` to see the specific section

Never read entire large files when a targeted search will do.

---

## Step 6 — Implementation

Follow the plan from CHANGE.md (if created). Check off `Plan` items as you complete them.

Apply project style — read `CLAUDE.md` for restrictions.

---

## Step 7 — Verification

Read `.protocol/config.yaml` for commands. Run what applies:

- After any logic change: `test`
- After any file edit: `lint`
- After type-relevant changes: `typecheck`
- Before declaring complete: `build`

Update `STATE.md Last verified` with the result:

```
Last verified: <commit> + <clean|dirty> worktree, <date>, <passed|partial|failed|not-run>
```

**Do not declare the task complete if verification fails.** Fix the failure, then re-run.

---

## Step 8 — Completion

**Small task**: state what was done in one sentence.

**Standard / High-risk / Epic**: update CHANGE.md:
- Fill in `Result` section
- Mark all `Plan` checklist items as done (`- [x]`)
- Change `status: in-progress` → `status: done`

Do not archive the change yet — `protocol-handoff` does that.
