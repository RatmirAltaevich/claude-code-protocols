# Workflow

## Core idea

> Memory always. Specification when needed. No duplicate source of truth.

The protocol scales process to task size. A typo fix gets zero overhead. A database migration gets a plan, approval, and a decision record.

## Task classification

```
Request
  ↓
Classify size and risk
  ↓
Small     → execute directly
Standard  → CHANGE.md
High-risk → CHANGE.md + plan approval
Epic      → extended CHANGE.md + approval
  ↓
Implement
  ↓
Verify (test / lint / typecheck / build)
  ↓
Handoff
  ↓
Archive change + update decisions
```

## Classification rules

| Type | Conditions | Process |
|------|-----------|---------|
| Small | 1–2 files, no behavior change, no risk keywords | No CHANGE.md. Execute. |
| Standard | Multiple files or new behavior | CHANGE.md, then proceed |
| High-risk | Risk keyword from config.yaml | CHANGE.md + stop for approval |
| Epic | New subsystem (>5 files, >1 week) | Extended CHANGE.md + approval |

Default risk keywords: `database-migration`, `authentication`, `payments`, `public-api`, `production`, `destructive-operation`

## CHANGE.md lifecycle

```
.protocol/changes/active/CHG-001.md   ← created at task start
  → status: done, result filled         ← at task completion
  → .protocol/changes/archive/2026/    ← archived by protocol-handoff
```

## DECISIONS.md rules

Capture a decision when:
- A choice between multiple approaches was made
- A constraint is not visible from the code alone
- Something would break if a future agent "improved" it

Do **not** capture:
- Obvious style choices
- Things clear from reading the code
- Routine task steps

Decision statuses:
- `Active` — currently in force
- `Superseded` — replaced by a newer decision (link to D-NNN)
- `Retired` — no longer applies (code was removed or approach abandoned)

Never auto-archive by age. Age does not determine relevance.

## STATE.md rules

Keep only what cannot be reliably derived from the code:
- Current deployment state
- What is actively in progress
- What is blocked and why
- The next concrete action

Remove from STATE.md:
- API routes (in route files)
- Database schema (in migration files)
- Dependency versions (in package files)
- Folder structure (derivable with `ls`)
- Env var descriptions (in .env.example)

## Navigation fallback

The protocol does not require codebase-memory-mcp. Navigation order:

1. `codebase-memory-mcp` if available and project is indexed
2. Language server / LSP if available
3. `rg` (ripgrep) + targeted `Read` — always works

Set `navigation.provider: auto` in config.yaml to let the skill choose.
