# Continuity Protocol

> Memory always. Specification when needed. No duplicate source of truth.

A Claude Code plugin that gives any project persistent memory and an adaptive workflow — without duplicating what the code already knows.

## Install

```
/plugin marketplace add RatmirAltaevich/claude-code-protocols
/plugin install continuity@claude-code-protocols
```

If Claude Code prompts you to reload after installation:

```
/reload-plugins
```

Then in your project:

```
/continuity:protocol-init
```

That's it. The skill detects your project type, finds existing docs, creates `.protocol/`, and adds a managed block to `CLAUDE.md`.

## What it does

After init, every Claude Code session automatically sees your current state and open changes (via a `SessionStart` hook). You get four slash commands:

| Command | When to use |
|---------|-------------|
| `/continuity:protocol-work` | Start of any non-trivial task |
| `/continuity:protocol-handoff` | End of session or after a major task |
| `/continuity:protocol-audit` | Periodic health check |
| `/continuity:protocol-init` | First time setup (re-runnable) |

## What gets created

```
your-project/
├── CLAUDE.md                          ← gets a managed block added
└── .protocol/
    ├── config.yaml                    ← project name, commands, risk config
    ├── STATE.md                       ← current state (branch, in-progress, next)
    ├── DECISIONS.md                   ← architectural decisions with status
    ├── changes/
    │   ├── active/CHG-001.md          ← open changes
    │   └── archive/2026/CHG-001.md   ← completed changes
    └── runtime/                       ← gitignored session data
```

## Adaptive workflow

Tasks are classified by size and risk:

```
Small task (1-2 files, no risk)  →  execute directly
Standard task                    →  CHANGE.md, then proceed
High-risk (auth, payments, etc.) →  CHANGE.md + plan approval
Epic (new subsystem)             →  extended planning
```

Risk keywords are configurable in `.protocol/config.yaml`.

## DECISIONS.md — why this matters

The protocol captures *reasons*, not just *what was done*. Each decision has:

```markdown
## D-001 — Synchronous generation kept

Status: Active
Date: 2026-08-01
Related code: `src/generation/service.ts`

### Decision
Generation is synchronous — client waits for result.

### Why
Async caused duplicate orders when users re-submitted. Three prod incidents.

### Do not change because
Duplicate charges reappear. Happened 2026-07-01, 2026-07-14, 2026-07-31.
```

Future sessions read this before touching related code. No more "let me make this async for performance" surprises.

## STATE.md — slim by design

Only what cannot be derived from the code:

```markdown
# Current state

Updated: 2026-08-13
Branch: main
Active change: CHG-003
Last verified commit: 2109860

## Current
Auth and generation working in prod. Payment flow in test.

## In progress
CHG-003: FreedomPay webhook integration

## Blocked
Waiting for FreedomPay sandbox credentials.

## Next
Test webhook locally once credentials arrive.
```

Not in STATE.md: API routes, DB schema, env vars, folder structure, dependency versions.

## Navigation — MCP optional

The protocol works without codebase-memory-mcp:

```
codebase-memory-mcp available  →  graph search (fastest)
Language server available       →  symbol lookup
Neither                         →  rg + targeted file reads (always works)
```

Set `navigation.provider: auto` and the skill picks automatically.

## Hooks

Two lightweight hooks are included:

- **SessionStart** — reads STATE.md and active CHANGEs, injects them as context
- **PostToolUse(Write/Edit)** — logs modified files to `.protocol/runtime/`

No Stop hook. Sessions end cleanly.

## Migrating from v1

If you used the v1 templates (AGENT_START_HERE.md, PROGRESS_LOG.md):

```
/continuity:protocol-init
```

The skill detects them and offers to migrate. See [migration guide](docs/migration-v1-v2.md).

## v1 templates

The original template files are preserved in [`legacy/v1/`](legacy/v1/) for reference.

## Compatibility

- Claude Code CLI: v2.1.x+
- Node.js: 20+ (for hooks-handlers)
- Works with Python, Node.js, Rust, Go projects

---

MIT License · [RatmirAltaevich](https://github.com/RatmirAltaevich)
