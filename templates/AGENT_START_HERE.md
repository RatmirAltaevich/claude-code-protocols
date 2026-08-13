# [Project Name] — Project Documentation

> Updated: YYYY-MM-DD (session N).

---

## 🟢 Current status

**Last session (N):** [What was done]

**Currently in prod:** [What's deployed and running]

**In progress / open:** [Open tasks or "none"]

---

## ⚡ IMMEDIATELY: MCP tools are connected and ready

Don't waste tokens on grep and sequential file reads. Use:

```
Find function:    mcp__codebase-memory-mcp__search_graph(name_pattern="...", project="my-project")
Function source:  mcp__codebase-memory-mcp__get_code_snippet(qualified_name="...", project="my-project")
Who calls X:      mcp__codebase-memory-mcp__trace_path(function_name="...", project="my-project", direction="inbound")
What X calls:     mcp__codebase-memory-mcp__trace_path(function_name="...", project="my-project", direction="outbound")
Text search:      mcp__codebase-memory-mcp__search_code(pattern="...", project="my-project")
Architecture:     mcp__codebase-memory-mcp__get_architecture(project="my-project")
```

Project indexed: `"my-project"` (N nodes).
After major changes: `index_repository(repo_path="<path>", name="my-project")`.

---

## Where to start (required order)

1. **`CLAUDE.md`** — restrictions, rules, deploy order
2. **`PROGRESS_LOG.md`** — decision history and reasons. **Read fully.** The "why" behind every non-obvious architectural choice is there.
3. **`AGENT_START_HERE.md`** (this file) — infrastructure, APIs, current status

**Rule:** if you want to change something architectural (provider, model, API endpoint, handler flow) — first search PROGRESS_LOG for whether this has been tried before and why it was abandoned.

---

## What this project is

<!-- Brief description of the project -->

**[Project name]** — [One sentence: what it does, who uses it, what stack].

---

## Infrastructure

| Component | Where |
|---|---|
| Backend | [Platform — Railway / Render / etc.] |
| Frontend | [Platform — Vercel / Netlify / etc.] |
| Database | [Supabase / PlanetScale / etc.] |
| [Other] | [Details] |

---

## Critical dependency — package versions

```
[package]==X.Y.Z    ← DO NOT update! [reason]
[package]==A.B.C    ← requires [constraint]
```

---

## Environment variables

| Variable | Service | What it does |
|---|---|---|
| `API_KEY` | Production | [Description] |
| `DATABASE_URL` | All | [Description] |

---

## API routes

| Method | Route | What it does |
|---|---|---|
| `POST` | `/api/generate` | [Description] |
| `GET` | `/api/status` | [Description] |

---

## Database schema (key tables)

| Table | What's stored |
|---|---|
| `users` | [Description] |
| `[table]` | [Description] |
