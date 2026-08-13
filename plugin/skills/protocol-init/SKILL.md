---
name: protocol-init
description: Initialize or migrate Continuity Protocol in an existing project without overwriting user documentation.
disable-model-invocation: true
---

# Protocol Init

Initialize the Continuity Protocol in a project. Creates `.protocol/` with adaptive workflow infrastructure.

**Safe to re-run** — never overwrites user content. Idempotent.

---

## What this skill does

1. Detects project type and extracts verification commands from config files
2. Scans for existing documentation (CLAUDE.md, AGENT_START_HERE.md, PROGRESS_LOG.md, ADR)
3. Creates `.protocol/` folder structure
4. Writes `config.yaml` from template with detected values
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

Create `.protocol/config.yaml` only if it does not exist.

Copy `${CLAUDE_PLUGIN_ROOT}/templates/config.yaml` and fill in detected values:
- `project`: name from package.json/pyproject.toml, or directory basename
- `commands`: detected commands from Step 1
- `documentation.existing_adr`: add if ADR folder was found

---

## Step 5 — Create STATE.md

Copy `${CLAUDE_PLUGIN_ROOT}/templates/STATE.md` and fill in:
- `Updated`: today's date
- `Branch`: current git branch (`git rev-parse --abbrev-ref HEAD`)
- `Last verified`: `— not-run`

If `AGENT_START_HERE.md` exists: offer to migrate.

**If migrating**: extract the "Current status" / "Текущий статус" section into STATE.md format. Skip infrastructure details (env vars, API routes, DB schema, package versions) — those belong in the code and docs, not STATE.md.

---

## Step 6 — Create DECISIONS.md

Copy `${CLAUDE_PLUGIN_ROOT}/templates/DECISIONS.md`.

If `PROGRESS_LOG.md` exists: offer to migrate.

**If migrating**: convert each entry. Mapping:
- `**Решение:**` / `**Decision:**` → `### Decision`
- `**Причина:**` / `**Why:**` / `**Reason:**` → `### Why`
- `**НЕ МЕНЯТЬ потому что:**` / `**Do not change because:**` → `### Do not change because`
- Set `Status: Active` for all entries

Also ask: "Should I populate the PINNED table with the most critical migrated decisions?" If yes, add up to 5 rows to the PINNED table.

---

## Step 7 — Update CLAUDE.md

**If CLAUDE.md does not exist**: create it:

```markdown
# Project instructions

<!-- continuity:start -->
Project lifecycle is managed through `.protocol/`.

Before non-trivial work:
1. Read `.protocol/STATE.md`.
2. Read the PINNED table in `.protocol/DECISIONS.md`.
3. Check `.protocol/changes/active/` for open changes.
4. Run verification commands from `.protocol/config.yaml`.

Do not duplicate information obtainable from the code or config files.
<!-- continuity:end -->

## Project-specific restrictions

<!-- Add project-specific rules below this line -->
```

**If CLAUDE.md exists and has no `<!-- continuity:start -->` marker**: insert the block between the first heading and the first paragraph. Do not modify existing user content.

**If CLAUDE.md already has `<!-- continuity:start -->`**: skip — already initialized.

The managed block is created during initialization and updated only by `protocol-init` or a future protocol upgrade. It is not automatically kept current.

---

## Step 8 — Confirm

```
✓ .protocol/ created
✓ config.yaml — commands: test=<cmd>, lint=<cmd>, typecheck=<cmd>, build=<cmd>
✓ STATE.md — <created | migrated from AGENT_START_HERE.md>
✓ DECISIONS.md — <created | migrated N entries from PROGRESS_LOG.md>
✓ CLAUDE.md — <created | managed block added | already initialized>
✓ .gitignore — .protocol/runtime/ excluded

Next: /continuity:protocol-work
```

If commands were auto-detected, tell the user to verify them in `.protocol/config.yaml`.
