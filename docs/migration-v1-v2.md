# Migration from v1 to v2

v1 was a set of templates you copied manually. v2 is an installable plugin with adaptive workflow.

## What changed

| v1 | v2 |
|----|----|
| `AGENT_START_HERE.md` | `.protocol/STATE.md` (slimmer, no infra dumps) |
| `PROGRESS_LOG.md` | `.protocol/DECISIONS.md` (with status, no date-based archiving) |
| `project-CLAUDE.md` template | Managed `<!-- continuity:start -->` block in CLAUDE.md |
| Manual copy of templates | `/continuity:protocol-init` sets up automatically |
| No workflow guidance | Four skills: init, work, handoff, audit |
| No change tracking | `.protocol/changes/` with CHANGE.md lifecycle |
| MCP required | MCP optional — falls back to rg + file reads |

## Migration steps

1. Install the plugin:
   ```
   /plugin marketplace add RatmirAltaevich/claude-code-protocols
   /plugin install continuity
   ```

2. Run init — it detects existing v1 files and offers to migrate:
   ```
   /continuity:protocol-init
   ```

3. The skill will ask:
   - "Migrate AGENT_START_HERE.md → STATE.md?" → say yes, it extracts the current status, discards infra dumps
   - "Migrate PROGRESS_LOG.md → DECISIONS.md?" → say yes, it converts entries to the new format

4. Review the result:
   - `.protocol/STATE.md` — should be short (under 30 lines)
   - `.protocol/DECISIONS.md` — each entry has Status, Why, Do not change because
   - `CLAUDE.md` — now has a `<!-- continuity:start -->` managed block; your project-specific rules below it

5. The old files (AGENT_START_HERE.md, PROGRESS_LOG.md) are not deleted — you can archive or delete them manually after verifying the migration.

## What to trim from STATE.md after migration

STATE.md should contain only what cannot be derived from the code. Remove:
- Supabase table names and schema (use the migration files)
- API route tables (use the route files)
- Env var descriptions (use .env.example)
- MCP graph node counts
- Railway/Vercel URL tables
- Dependency version pins (use package.json/requirements.txt)

Keep:
- What is currently deployed and working
- What is in progress or blocked
- The next concrete action
- Active change reference (CHG-NNN)

## CLAUDE.md after migration

After init, CLAUDE.md has a managed block (automatically kept current) and a user section (yours to edit). The managed block replaces the long startup reading protocol from v1.

The global `~/.claude/CLAUDE.md` is still useful for:
- MCP tool protocol (codebase-memory-mcp, Context7)
- Cross-project preferences
- Global code style rules

It is no longer the only place for project lifecycle instructions — that moves into the plugin skills and project-level `.protocol/`.
