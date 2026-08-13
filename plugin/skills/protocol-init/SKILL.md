# /continuity:protocol-init

Initialize the Continuity Protocol in a project. Creates `.protocol/` with adaptive workflow infrastructure.

**Safe to re-run** — never overwrites user content. Idempotent.

---

## What this skill does

1. Detects project type and extracts verification commands from config files
2. Scans for existing documentation (CLAUDE.md, AGENT_START_HERE.md, PROGRESS_LOG.md, ADR)
3. Creates `.protocol/` folder structure
4. Writes `config.yaml` with detected values
5. Creates `STATE.md` and `DECISIONS.md` (optionally migrating from existing files)
6. Adds a managed block to `CLAUDE.md`

---

## Step 1 — Detect project type

Run in parallel:

```bash
ls package.json pyproject.toml Cargo.toml go.mod pom.xml 2>/dev/null
```

Read the first found config file (first 40 lines) to extract:
- **Project name**: `name` field in package.json / pyproject.toml
- **Verification commands**:
  - Node.js → from `scripts`: `test`, `lint` / `lint:check`, `typecheck` / `type-check`, `build`
  - Python → `pytest` or `python -m pytest`, `ruff check .` or `flake8`, `mypy .`
  - Rust → `cargo test`, `cargo clippy -- -D warnings`, `cargo build`
  - Go → `go test ./...`, `go vet ./...`, `go build ./...`

If no recognizable config: leave command fields empty, user fills in later.

---

## Step 2 — Scan existing documentation

```bash
ls CLAUDE.md AGENT_START_HERE.md PROGRESS_LOG.md .protocol/ 2>/dev/null
find . -name "*.md" -path "*/adr/*" -not -path "./.git/*" 2>/dev/null | head -10
```

Note which files exist. This determines migration options in steps 5 and 6.

---

## Step 3 — Create `.protocol/` structure

```bash
mkdir -p .protocol/changes/active .protocol/changes/archive .protocol/runtime
```

Add `.protocol/runtime/` to `.gitignore`:
- If `.gitignore` exists: append `# Continuity Protocol runtime\n.protocol/runtime/` (only if not already present)
- If no `.gitignore`: create it with that line

---

## Step 4 — Write `config.yaml`

Create `.protocol/config.yaml` only if it does not exist:

```yaml
schema: 1
project: <name from package.json/pyproject.toml or directory basename>

commands:
  test: <detected or "">
  lint: <detected or "">
  typecheck: <detected or "">
  build: <detected or "">

documentation:
  instructions: CLAUDE.md
  state: .protocol/STATE.md
  decisions: .protocol/DECISIONS.md

navigation:
  provider: auto   # auto = use codebase-memory-mcp if available, else rg + file reads

risk:
  require_approval:
    - database-migration
    - authentication
    - payments
    - public-api
    - production
    - destructive-operation
```

If `existing_adr` folder was found: add `existing_adr: <path>` under `documentation`.

---

## Step 5 — Create STATE.md

If `AGENT_START_HERE.md` exists: offer to migrate.

**If migrating**: extract the "Current status" / "Текущий статус" section into STATE.md format below. Skip infrastructure details (env vars, API routes, DB schema, package versions) — those belong in the code and docs, not STATE.md.

**If not migrating or file absent**: create from template:

```markdown
# Current state

Updated: <YYYY-MM-DD>
Branch: <current git branch, or "main">
Active change: none
Last verified commit: <git rev-parse --short HEAD, or "—">

## Current

<what is working and deployed — leave blank if unknown>

## In progress

none

## Blocked

none

## Next

Run /continuity:protocol-work on your first task.
```

---

## Step 6 — Create DECISIONS.md

If `PROGRESS_LOG.md` exists: offer to migrate.

**If migrating**: convert each entry. Mapping:
- `**Решение:**` / `**Decision:**` → `### Decision`
- `**Причина:**` / `**Why:**` / `**Reason:**` → `### Why`
- `**НЕ МЕНЯТЬ потому что:**` / `**Do not change because:**` → `### Do not change because`
- Set `Status: Active` for all entries

**If not migrating or absent**: create with one commented example entry:

```markdown
# Decisions

Active architectural decisions and the reasoning behind them.
Status: Active | Superseded | Retired

<!--
## D-001 — Example decision title

Status: Active
Date: YYYY-MM-DD
Related code: `src/example.ts`

### Decision

What was decided.

### Why

The reason — constraint, incident, stakeholder requirement.

### Do not change because

What breaks if this is reversed.
-->
```

---

## Step 7 — Update CLAUDE.md

**If CLAUDE.md does not exist**: create it:

```markdown
# Project instructions

<!-- continuity:start -->
Project lifecycle is managed through `.protocol/`.

Before non-trivial work:
1. Read `.protocol/STATE.md`.
2. Read active and pinned decisions in `.protocol/DECISIONS.md`.
3. Check `.protocol/changes/active/` for open changes.
4. Run verification commands from `.protocol/config.yaml`.

Do not duplicate information obtainable from the code or config files.
<!-- continuity:end -->

## Project-specific restrictions

<!-- Add project-specific rules below this line -->
```

**If CLAUDE.md exists and has no `<!-- continuity:start -->` marker**: insert the block between the first heading and the first paragraph (or at the top of the file if no heading). Do not modify any existing user content.

**If CLAUDE.md already has `<!-- continuity:start -->`**: skip — already initialized.

---

## Step 8 — Confirm

Print a summary:

```
✓ .protocol/ created
✓ config.yaml — commands: test=<cmd>, lint=<cmd>, typecheck=<cmd>, build=<cmd>
✓ STATE.md — <created | migrated from AGENT_START_HERE.md>
✓ DECISIONS.md — <created | migrated N entries from PROGRESS_LOG.md>
✓ CLAUDE.md — <created | managed block added | already initialized>
✓ .gitignore — .protocol/runtime/ excluded

Next: /continuity:protocol-work
```

If commands were auto-detected, tell the user to check them and correct in `.protocol/config.yaml` if needed.
