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

The session id is **not** available as an environment variable — do not try to
read one. `CLAUDE_SESSION_ID` does not exist, and guessing produces a directory
the hooks never look at, so the handoff marker in Step 6 would be written where
`SessionEnd` cannot find it.

Take the path from the `Session runtime:` line the SessionStart hook put in your
context. If that line is not present, fall back to the most recently touched
runtime directory — the hooks create it as soon as the session edits anything:

```bash
SESSION_DIR=$(
  ls -dt .protocol/runtime/*/ 2>/dev/null | head -1
)
SESSION_DIR="${SESSION_DIR%/}"
```

If neither is available, no session runtime exists yet: skip to Step 1 and skip
Step 6 as well — there is nothing for `SessionEnd` to clean up.

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
) || true

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

## Step 6 — Mark session as handed off

Write a marker so `SessionEnd` knows handoff already ran and skips creating a recovery snapshot:

```bash
# $SESSION_DIR is resolved in Step 0 — reuse it, do not recompute an id here.
# Skip this step entirely if Step 0 found no session runtime.
[ -n "$SESSION_DIR" ] && touch "$SESSION_DIR/handoff-complete"
```

The marker must land in the directory the hooks actually use. Writing it to a
guessed id means `SessionEnd` never sees it, writes a recovery snapshot anyway,
and the next session opens with a false "aborted session" warning.

Do not `rm -rf` the directory here — `SessionEnd` will clean it up cleanly when it fires.
Do not touch other session directories.

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
