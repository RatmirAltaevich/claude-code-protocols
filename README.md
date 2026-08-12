# claude-code-protocols

A production-tested protocol system for Claude Code that eliminates wasted tokens, lost context between sessions, and repeated mistakes.

Built from real project experience — not theory.

---

## The problem

Claude Code is powerful but stateless. Without structure:
- Every session starts from scratch
- The same mistakes happen again and again
- Claude reads the wrong files, in the wrong order, using the wrong tools
- Architectural decisions get "improved" by an agent that doesn't know they were already tried

## The solution

Two-level documentation that gives Claude the right context, in the right order, every time.

```
~/.claude/CLAUDE.md          ← global: HOW to work (navigation, library, session protocols)
your-project/CLAUDE.md       ← project: WHAT to know (stack, restrictions, patterns)
your-project/AGENT_START_HERE.md  ← current status, infra, what's in progress
your-project/PROGRESS_LOG.md      ← decision history: why the code is the way it is
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

See [setup/mcp-setup.md](setup/mcp-setup.md) for full instructions.

```bash
npm install -g codebase-memory-mcp
npm install -g @context7/mcp
```

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

### Code navigation (the core protocol)

Instead of reading files blindly, Claude follows a strict chain:

```
search_graph → get_code_snippet → trace_path → Read (last resort)
```

This cuts token usage by 60–80% on code exploration tasks. The graph finds the exact function in milliseconds; Claude reads only what it needs.

### Session continuity

`AGENT_START_HERE.md` is the first thing Claude reads — it knows immediately what's in production, what's in progress, and what's blocked. No re-deriving context.

`PROGRESS_LOG.md` prevents repeated mistakes. Every non-obvious architectural decision is logged with *why* — so Claude doesn't "improve" something that was already tried and failed.

### Two-level documentation

Global `CLAUDE.md` defines *how* to work — protocols that apply everywhere. Project `CLAUDE.md` defines *what* to know — stack, restrictions, deployment, patterns. No duplication, clear hierarchy.

---

## The navigation protocol in detail

The global CLAUDE.md enforces this decision tree for any code exploration:

| Task | Tool |
|---|---|
| Find function by name | `search_graph(name_pattern="my_function")` |
| Find by behavior | `search_graph(query="upload handler that resizes images")` |
| Read function source | `get_code_snippet(qualified_name="project.module.function")` |
| Who calls X | `trace_path(function_name="X", mode="calls")` |
| What X calls | `trace_path(function_name="X")` |
| Text pattern | `search_code(pattern="asyncio.to_thread")` |
| Project structure | `get_architecture(project="...")` |

**STOP rules** embedded in the protocol:
- Got a `qualified_name` → use `get_code_snippet`, never `Read` by line range
- `search_code` only if `search_graph` found nothing
- Never read a full file when you have a line number — `Read[offset=N, limit=30]` max

---

## PROGRESS_LOG format

Every non-obvious decision gets logged:

```markdown
### Decision name (YYYY-MM-DD)
**Decision:** What exactly was done — specific.
**Reason:** Why. What the problem was, what was tried before.
**DO NOT CHANGE because:** What breaks if reverted.
```

The pinned table at the top surfaces the most critical decisions immediately — the ones where "improving" without context causes production incidents.

---

## Session end protocol

After any non-trivial session:

1. **PROGRESS_LOG.md** — add entry if: provider/model change, architecture change, non-trivial bug, rejected "obvious" solution
2. **AGENT_START_HERE.md** — update date, session number, current status
3. **Graph** — `index_repository` if files were added or renamed

---

## Why this works

This system was built over dozens of sessions on a real production project. The protocols were derived from actual failure modes:

- Claude using `Read` on a 500-line file to find a 10-line function → fixed by mandatory `search_graph` first
- The same architectural mistake made three sessions in a row → fixed by PROGRESS_LOG pinned table
- Context lost between sessions requiring 20 minutes of re-derivation → fixed by AGENT_START_HERE
- Library code written from training data instead of current docs → fixed by Context7 protocol

---

## Contributing

The protocols are general — the templates are starting points. Adapt to your stack and document what actually broke in your project.

If you add a pattern from a real production incident, it belongs in `PROGRESS_LOG.md` and optionally in the project `CLAUDE.md` as a critical pattern.
