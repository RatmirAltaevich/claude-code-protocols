---
name: protocol-handoff
description: Verify work, update project state, capture decisions and archive completed changes at the end of a task or session.
disable-model-invocation: true
---

# Protocol Handoff

End-of-session wrap-up. Updates STATE.md, captures decisions, archives completed changes.

Use at the end of a session or after a significant task is complete.

---

## Step 0 — Load session runtime

Determine `CLAUDE_SESSION_ID` from the environment (or use `unknown` as fallback).

```bash
SESSION_DIR=".protocol/runtime/${CLAUDE_SESSION_ID:-unknown}"
```

If `$SESSION_DIR/tracked-files.txt` exists, read it. Compare against `git status --short` to confirm which files were actually modified this session. Show the user a combined list.

If other session directories exist in `.protocol/runtime/` besides the current one, check for `recovery.json` in each:
- If found: surface a warning — a previous session ended without handoff
- Do not auto-clean other sessions

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

Determine the next D-NNN number:

```bash
last_decision=$(
  grep -oE '^## D-[0-9]+' .protocol/DECISIONS.md 2>/dev/null \
    | grep -oE 'D-[0-9]+' \
    | sort -V \
    | tail -1
)

if [ -z "$last_decision" ]; then
  next_decision="D-001"
else
  number=${last_decision#D-}
  next_decision=$(printf 'D-%03d' "$((10#$number + 1))")
fi
```

Append to the `## Entries` section of `.protocol/DECISIONS.md`:

```markdown
## D-NNN — <title>

Status: Active
Date: <YYYY-MM-DD>
Areas: <affected risk categories>
Related code: `<file or function>`

### Decision

<what was decided, concisely>

### Why

<the reason — constraint, past incident, stakeholder requirement>

### Do not change because

<what breaks if reversed>
```

If the new decision is broadly critical, also add a row to the PINNED table.

---

## Step 4 — Update STATE.md

Rewrite `.protocol/STATE.md` to reflect current reality:

```markdown
# Current state

Updated: <YYYY-MM-DD>
Branch: <current git branch>
Active change: <CHG-NNN or none>
Last verified: <commit> + <clean|dirty> worktree, <date>, <passed|partial|failed|not-run>

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

## Step 6 — Clean up session runtime

After a successful handoff, remove only the current session's runtime directory:

```bash
rm -rf ".protocol/runtime/${CLAUDE_SESSION_ID:-unknown}"
```

Do not delete other session directories — they may belong to parallel sessions or contain unhandled recovery snapshots.

---

## Step 7 — Confirm

```
SESSION HANDOFF — <date>

Verification: test ✓ | lint ✓ | typecheck ✓ | build ✓
Decisions captured: D-<NNN> (<title>)
Changes archived: CHG-<NNN> → archive/<year>/
STATE.md updated.
Session runtime cleaned.

Next: <what was set in STATE.md → Next>
```
