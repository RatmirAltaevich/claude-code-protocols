# /continuity:protocol-handoff

End-of-session wrap-up. Updates STATE.md, captures decisions, archives completed changes.

Use at the end of a session or after a significant task is complete.

---

## Step 1 — Check git state

```bash
git status --short
git diff --stat HEAD 2>/dev/null || true
git rev-parse --short HEAD 2>/dev/null
```

If there are uncommitted changes that should be committed: remind the user. Do not commit yourself unless explicitly asked.

---

## Step 2 — Run verifications

Read `.protocol/config.yaml`. Run all applicable verification commands. Report pass/fail for each.

If any fail: note them in the STATE.md "Blocked" section rather than silently skipping.

---

## Step 3 — Capture decisions

Review what was done this session. Add a DECISIONS.md entry for each non-obvious choice:

- A choice between multiple approaches (what was picked and why)
- A constraint not visible from the code alone
- Something that would break if a future agent "improved" it
- A failed approach that should not be retried

**Do not document**: obvious choices, style preferences, things clear from the code, routine task steps.

Append to `.protocol/DECISIONS.md`:

```markdown
## D-NNN — <title>

Status: Active
Date: <YYYY-MM-DD>
Related code: `<file or function>`

### Decision

<what was decided, concisely>

### Why

<the reason — constraint, past incident, stakeholder requirement>

### Do not change because

<what breaks if reversed>
```

Use the next sequential D-NNN number.

---

## Step 4 — Update STATE.md

Rewrite `.protocol/STATE.md` to reflect current reality:

```markdown
# Current state

Updated: <YYYY-MM-DD>
Branch: <current git branch>
Active change: <CHG-NNN or none>
Last verified commit: <git rev-parse --short HEAD>

## Current

<what is working and deployed — specific, not generic>

## In progress

<what is not finished, or "none">

## Blocked

<any blockers including failed verifications, or "none">

## Next

<the single most concrete next action>
```

Keep it short. No API routes, no DB schema, no dependency versions, no folder structure — those are in the code.

---

## Step 5 — Archive completed changes

For each `.protocol/changes/active/CHG-NNN.md` where:
- `status: done`
- All `- [ ]` Plan items are checked
- `Result` section is filled

Run:

```bash
year=$(date +%Y)
mkdir -p .protocol/changes/archive/$year
mv .protocol/changes/active/CHG-NNN.md .protocol/changes/archive/$year/CHG-NNN.md
```

Leave incomplete changes in `active/`.

---

## Step 6 — Confirm

```
SESSION HANDOFF — <date>

Verification: test ✓ | lint ✓ | typecheck ✓ | build ✓
Decisions captured: D-<NNN> (<title>)
Changes archived: CHG-<NNN> → archive/<year>/
STATE.md updated.

Next: <what was set in STATE.md → Next>
```
