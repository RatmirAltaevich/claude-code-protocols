# [Project Name] — Claude Code Instructions

> Navigation, library, and session protocols → global `~/.claude/CLAUDE.md`.
> This file contains only project-specific rules.

---

## 1. Required reading order at session start

Read ALL files before writing code or making architectural decisions:

| # | File | What's there |
|---|------|------|
| 1 | `CLAUDE.md` | **This file** — rules, restrictions, deploy order |
| 2 | `PROGRESS_LOG.md` | Read PINNED decisions first; load relevant entries before changing architecture or behavior connected to those decisions. |
| 3 | `AGENT_START_HERE.md` | Infrastructure, APIs, env vars, current status |
| 4 | `SCALING.md` | Current scaling plan — what stage, what's next *(remove if not applicable)* |
| 5 | `RUNBOOK.md` | What to do when something breaks. Read only during an incident. |

**Rule:** read the PINNED section for every task. Read relevant full entries before changing architecture or behavior connected to those decisions.

---

## 2. Decision log (PROGRESS_LOG.md)

> Format and triggers → global `~/.claude/CLAUDE.md` §4.

---

## 3. Commits

Commit specific files, not `git add -A`. Message format:
```
type: brief description

Details if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`.

---

## 4. Deploy

<!-- Customize for your stack -->

| Service | Command | When to deploy |
|---------|---------|----------------|
| **production** | `<deploy command>` | Changes affect prod flow |
| **staging** | `<deploy command>` | Changes for testing only |

**Mandatory pre-deploy checklist:**
1. Check env vars of the target service
2. Understand which service is actually affected
3. Ensure the commit exists
4. Test on staging before production for business logic changes

---

## 5. Critical restrictions

| Restriction | Reason |
|--------|---------|
| **DO NOT** update `[locked-package]` | Version conflict — breaks everything. See PROGRESS_LOG. |
| **DO NOT** commit env files, keys, credentials | They're in .gitignore |
| **DO NOT** `git add -A` | Specific files only |

---

## 6. Architecture — what not to break

<!-- Document the non-obvious constraints specific to your project -->

- **[Constraint 1]** — reason why it must stay this way
- **[Constraint 2]** — reason why it must stay this way

---

## 7. Critical code patterns

<!-- Add patterns from real production incidents -->

### P1: [Pattern name]

```python
# REQUIRED ORDER — all N steps:
# step 1
# step 2
# step 3
```

Violation → [what breaks]. Happened N times in production.
