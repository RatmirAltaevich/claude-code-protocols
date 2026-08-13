# /continuity:protocol-work

Adaptive work cycle. Classifies the task, applies the right amount of process, implements, verifies.

Invoke this skill at the start of any non-trivial task. For obvious one-liner fixes, work directly — this skill adds overhead only when it reduces risk.

---

## Step 1 — Load context

Read in parallel:
1. `.protocol/STATE.md` — current project state
2. `.protocol/DECISIONS.md` — active and pinned decisions
3. `.protocol/changes/active/` — any open CHANGEs

```bash
cat .protocol/STATE.md 2>/dev/null
cat .protocol/DECISIONS.md 2>/dev/null
ls .protocol/changes/active/ 2>/dev/null
```

---

## Step 2 — Classify the task

Evaluate the user's request against these criteria:

| Type | Conditions | Process |
|------|-----------|---------|
| **Small** | 1–2 files, no behavior change, no risk keywords | Execute directly — no CHANGE.md |
| **Standard** | Multiple files, new behavior, or new public surface | Create CHANGE.md, proceed |
| **High-risk** | Contains risk keyword from `config.yaml` | CHANGE.md + **stop for plan approval** |
| **Epic** | New subsystem or major integration (>5 files, >1 week) | Extended CHANGE.md + approval |

**Risk keywords** (default, can be extended in `config.yaml risk.require_approval`):
`database-migration`, `authentication`, `payments`, `public-api`, `production`, `destructive-operation`

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
)

if [ -z "$last_change" ]; then
  next_change="CHG-001"
else
  number=${last_change#CHG-}
  next_change=$(printf 'CHG-%03d' "$((10#$number + 1))")
fi
```

This searches both `active/` and `archive/` recursively, so CHG numbers never reset after archiving.

Create `.protocol/changes/active/CHG-NNN.md`:

```markdown
---
id: CHG-NNN
status: in-progress
size: standard
risk: low | medium | high
created: YYYY-MM-DD
---

# <Change title — what is being built>

## Intent

Why this change is needed.

## Scope

What is included in this change.

## Out of scope

What is explicitly not being done here.

## Acceptance

- [ ] <Verifiable condition>
- [ ] <Verifiable condition>

## Constraints

Non-obvious constraints (existing decisions, locked packages, etc.).

## Plan

- [ ] Step 1
- [ ] Step 2
- [ ] Tests pass
- [ ] Verification commands pass

## Verification

Commands to run (from config.yaml):
- `<test command>`
- `<typecheck command>`

## Result

*Filled in after completion.*
```

Show the CHANGE.md to the user and proceed to implementation. No need to wait for explicit approval on Standard tasks.

---

## Step 3c — High-risk task

Create CHANGE.md with `size: high-risk` and **stop**.

Present the plan to the user:
- What will change specifically (files, functions, data)
- Rollback procedure
- Verification commands to confirm success

Wait for explicit user approval before making any changes to the codebase.

---

## Step 4 — Consult decisions before implementing

Before changing any of the following, check DECISIONS.md for a relevant entry:

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

**Do not declare the task complete if verification fails.** Fix the failure, then re-run.

---

## Step 8 — Completion

**Small task**: state what was done in one sentence.

**Standard / High-risk / Epic**: update CHANGE.md:
- Fill in `Result` section
- Mark all `Plan` checklist items as done (`- [x]`)
- Change `status: in-progress` → `status: done`

Do not archive the change yet — `protocol-handoff` does that.
