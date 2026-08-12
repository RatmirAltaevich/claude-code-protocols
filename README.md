# claude-code-protocols

A production-tested protocol system for Claude Code that reduces wasted context, prevents repeated mistakes, and gives Claude persistent memory across sessions.

Built from real project experience — not theory.

---

## The problem

Claude Code is powerful but stateless. Without structure:
- Every session starts from scratch — Claude re-derives context you already established
- Architectural decisions get "improved" by an agent that doesn't know they were already tried and failed
- Code navigation defaults to reading full files instead of jumping to exact symbols
- Library code gets written from training data, not current docs

## The solution

Four-layer documentation that gives Claude the right context, in the right order, every time.

```
~/.claude/CLAUDE.md               ← HOW to work: navigation, library, session protocols
your-project/CLAUDE.md            ← WHAT to know: stack, restrictions, critical patterns
your-project/PROGRESS_LOG.md      ← decision history: why the code is the way it is
your-project/AGENT_START_HERE.md  ← current status, infra, what's in progress
```

---

## What's included

```
claude-code-protocols/
├── global/
│   └── CLAUDE.md              # Drop into ~/.claude/CLAUDE.md
├── templates/
│   ├── project-CLAUDE.md      # Project-level instructions template
│   ├── AGENT_START_HERE.md    # Infrastructure + current status template
│   └── PROGRESS_LOG.md        # Decision log template
└── setup/
    └── mcp-setup.md           # codebase-memory-mcp + Context7 installation
```

---

## Quickstart

### 1. Install MCP servers

```bash
npm install -g codebase-memory-mcp
npm install -g @upstash/context7-mcp
```

See [setup/mcp-setup.md](setup/mcp-setup.md) for configuration details.

### 2. Set up global CLAUDE.md

```bash
cp global/CLAUDE.md ~/.claude/CLAUDE.md
```

Edit the "Indexed projects" table to add your project paths.

### 3. Add project files

```bash
cp templates/project-CLAUDE.md your-project/CLAUDE.md
cp templates/AGENT_START_HERE.md your-project/AGENT_START_HERE.md
cp templates/PROGRESS_LOG.md your-project/PROGRESS_LOG.md
```

Fill in the placeholders. The more accurate these are, the better Claude performs.

### 4. Index your codebase

In a Claude Code session:

```
index_repository(project="my-project", root_path="/path/to/my-project")
```

Update the "Indexed projects" table in `~/.claude/CLAUDE.md`.

---

## How it works

### Code navigation

Instead of reading files blindly, Claude follows a priority chain:

```
search_graph → get_code_snippet → trace_path → Read (last resort)
```

For source code: the graph finds the exact function in one call — Claude reads only what it needs. For configs, markdown, SQL, and other non-indexed files, standard tools like `grep` or `Read` are appropriate.

### Session continuity

`PROGRESS_LOG.md` prevents repeated mistakes. Every non-obvious architectural decision is logged with *why* — so Claude doesn't "improve" something that was already tried and failed.

`AGENT_START_HERE.md` surfaces current project state immediately — what's in production, what's in progress, what's blocked.

### Four-layer documentation

| Layer | File | Purpose |
|---|---|---|
| Global | `~/.claude/CLAUDE.md` | HOW to work — applies to every project |
| Project rules | `project/CLAUDE.md` | WHAT to know — stack, deploy, restrictions |
| Decision log | `PROGRESS_LOG.md` | WHY code is the way it is |
| Current state | `AGENT_START_HERE.md` | Status, infra, open tasks |

Each layer has a distinct job. No duplication between them.

---

## The navigation protocol

Decision table embedded in the global CLAUDE.md:

| Task | Tool |
|---|---|
| Find function by name | `search_graph(name_pattern="my_function")` |
| Find by behavior | `search_graph(query="upload handler that resizes images")` |
| Read function source | `get_code_snippet(qualified_name="project.module.function")` |
| Who calls X | `trace_path(function_name="X", mode="calls")` |
| What X calls | `trace_path(function_name="X")` |
| Text/pattern in any file | `search_code(pattern="asyncio.to_thread")` |
| Project structure | `get_architecture(project="...")` |

---

## PROGRESS_LOG format

Every non-obvious decision gets a structured entry:

```markdown
### Decision name (YYYY-MM-DD)
**Decision:** What exactly was done — specific.
**Reason:** Why. What the problem was, what was tried before.
**DO NOT CHANGE because:** What breaks if reverted.
```

The pinned table at the top surfaces the most critical decisions — the ones where "improving" without context causes production incidents.

---

## Session end protocol

After any non-trivial session:

1. **PROGRESS_LOG.md** — add entry if: provider/model change, architecture change, non-trivial bug, rejected "obvious" solution
2. **AGENT_START_HERE.md** — update date, session number, current status
3. **Graph** — `index_repository` if source files were added or renamed

---

## What made this necessary

This system was built over dozens of sessions on a real production project. The patterns came from actual failures:

- Claude using `Read` on a 500-line file to find a 10-line function → fixed by `search_graph` first
- The same architectural mistake made three sessions in a row → fixed by PROGRESS_LOG pinned table
- Context lost between sessions, requiring significant re-derivation → fixed by AGENT_START_HERE
- Library code written from stale training data → fixed by Context7 protocol

---

## Compatibility

- **Claude Code**: tested with Claude Sonnet 4.x and above
- **codebase-memory-mcp**: v0.10+, supports 158 languages
- **Context7 (`@upstash/context7-mcp`)**: v4.0+

---

## Contributing

The protocols are general — the templates are starting points. Adapt to your stack and document what actually broke in your project.

If you add a pattern from a real production incident, it belongs in `PROGRESS_LOG.md` and optionally in the project `CLAUDE.md` as a critical pattern.

---

## License

MIT — see [LICENSE](LICENSE).
