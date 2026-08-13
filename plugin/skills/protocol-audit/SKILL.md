# /continuity:protocol-audit

Audit `.protocol/` for health issues. Read-only — reports findings, makes no changes.

Run periodically or when documentation feels out of sync with the codebase.

---

## Checks

Run all checks in parallel where possible, then present results grouped by severity.

---

### Check 1 — Broken file references

For each `Related code:` line in DECISIONS.md and each file path mentioned in active CHANGEs:

```bash
ls <path> 2>/dev/null || echo "MISSING: <path>"
```

Flag any path that no longer exists.

---

### Check 2 — Stale active changes

For each file in `.protocol/changes/active/`:

```bash
ls -la .protocol/changes/active/
```

Read the `created:` date from frontmatter. Flag:
- **Stale**: `created` > 14 days ago AND `Plan` has unchecked `- [ ]` items
- **Not archived**: `status: done` AND all Plan items checked, but still in `active/`

---

### Check 3 — Decisions without status

For each `## D-NNN` entry in DECISIONS.md: verify it has one of:
- `Status: Active`
- `Status: Superseded`
- `Status: Retired`

Flag any entry missing a status line.

---

### Check 4 — Duplicate information

Scan CLAUDE.md and STATE.md for content that duplicates what the code already provides. Flag each occurrence:

| Pattern | Why it's a duplicate |
|---------|---------------------|
| API routes listed literally | Derivable from route files |
| Database schema descriptions | In migration files |
| Dependency list with versions | In package.json / pyproject.toml |
| Folder structure descriptions | Derivable by `ls` |
| Env var descriptions (beyond names) | In .env.example or deploy config |

Note: listing that something *exists* (e.g., "uses Supabase") is fine. Duplicating its full schema is not.

---

### Check 5 — Missing verification commands

Read `.protocol/config.yaml commands`. For each empty command field:

```bash
# Check if a config exists that implies the command should be set
ls package.json 2>/dev/null && echo "package.json found — test/lint/typecheck may be definable"
ls pyproject.toml 2>/dev/null && echo "pyproject.toml found — test command may be definable"
```

Flag empty commands when a corresponding project config exists.

---

### Check 6 — Incomplete changes marked done

For each active CHANGE.md where `status: done` but unchecked `- [ ]` items remain in the Plan section: flag as inconsistent.

---

### Check 7 — CLAUDE.md / config.yaml coherence

```bash
cat .protocol/config.yaml
```

Verify:
- `documentation.instructions` file exists
- `documentation.state` file exists
- `documentation.decisions` file exists
- If `documentation.existing_adr` is set: the path exists

Flag any missing files.

---

## Output format

```
PROTOCOL AUDIT — YYYY-MM-DD

✓ <N> checks passed

⚠ WARNINGS (<N>)
  CHG-002.md: stale (created 18 days ago, 3 unchecked plan items)
  DECISIONS.md D-004: missing Status line

✗ ERRORS (<N>)
  DECISIONS.md D-001 Related code: `src/old_handler.py` — file not found
  STATE.md: lists full DB schema (duplicate of migration files)

Suggested actions:
  - Run /continuity:protocol-handoff to archive completed changes
  - Add Status: to D-004
  - Remove schema description from STATE.md, keep only "uses Supabase (users, credits, generations tables)"
```

If everything passes:

```
PROTOCOL AUDIT — YYYY-MM-DD
✓ All checks passed. Protocol is healthy.
```
