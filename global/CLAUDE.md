# Global Claude Code Protocols

Place this file at `~/.claude/CLAUDE.md`.
It applies to **every project** you open in Claude Code.

---

## 1. Code Navigation Protocol

**The only allowed order:**

```
1. search_graph(name_pattern="..." or query="...")   → qualified_names + files + lines
2. get_code_snippet(qualified_name="...")             → exact function/class source
3. trace_path(function_name="...")                   → call chain up/down
4. Read file                                         → ONLY if qualified_name not found
```

**STOP rules:**
- Got `qualified_name` → `get_code_snippet`. Do NOT read file by offset/range.
- `search_code(pattern)` — only if `search_graph` found nothing.
- Found `file_path + line` → `Read[offset=line-2, limit=30]` max, not the whole file.
- Graph can't find an existing function → `index_repository` → retry.

**When to use what:**

| Task | Tool |
|---|---|
| Find function by name | `search_graph(name_pattern="my_function")` |
| Find by behavior description | `search_graph(query="photo upload handler")` |
| Read function source | `get_code_snippet(qualified_name="project.module.function")` |
| Who calls function X | `trace_path(function_name="X", mode="calls")` |
| What function X calls | `trace_path(function_name="X")` |
| Find text pattern | `search_code(pattern="asyncio.to_thread")` |
| Project architecture | `get_architecture(project="...", aspects=["overview"])` |

### Connected MCP servers

| Server | What it does | When |
|---|---|---|
| **codebase-memory-mcp** | Code graph: functions, classes, imports, calls | ALWAYS before grep/find/Read |
| **Context7** | Up-to-date library documentation | Before coding with any external library |

### Indexed projects

Add your projects here after running `index_repository`:

| Name | Path |
|---|---|
| `my-project` | `/path/to/my-project` |

Re-index: `index_repository(project="...", root_path="...")` — after adding, renaming, or refactoring files.

---

## 2. Library Protocol

Before writing code with any external library — strictly in this order:

```
1. resolve-library-id(libraryName="...")
2. get-library-docs(context7CompatibleLibraryID="...", topic="specific topic")
3. Write code
```

Required for libraries with locked versions or frequent breaking changes (e.g. aiogram v2 vs v3, supabase-py 2.x, Next.js, React).

**NEVER** write code using an external library from memory without checking current docs.

---

## 3. Session Start Protocol

```
1. MEMORY.md + global CLAUDE.md     ← auto-loaded, already read
2. project/CLAUDE.md                ← read
3. PROGRESS_LOG.md                  ← read
4. AGENT_START_HERE.md              ← read: current status and what's in progress
5. RUNBOOK.md / SCALING.md / etc.   ← only if the task involves them
```

---

## 4. Session End Protocol

After non-trivial work — in this order:

**Step 1 — PROGRESS_LOG.md** (if: provider/model/API change, architectural decision, non-trivial bug, rejection of the "obvious" solution):

```
### Decision name (YYYY-MM-DD)
**Decision:** What exactly was done — specific, no fluff.
**Reason:** Why. What the problem was, what was tried before.
**DO NOT CHANGE because:** What breaks or recurs if reverted.
```

Do NOT write: routine edits, things obvious from the code, descriptions of what the code does.

**Step 2 — AGENT_START_HERE.md:** update date + session number + "Current status" section.

**Step 3 — Graph:** `index_repository` if `.py` (or other indexed) files were added or renamed.

---

## 5. Code Style

- Comments only when WHY is non-obvious — never describe what the code does.
- Do not create new files unnecessarily — edit existing ones.
- Do not add error handling for situations that cannot happen.
- Commit only specific files, not `git add -A`.
- Do not add features beyond the task scope.

---

## 6. Scope

If the task does not require reading project files (texts, marketing, strategy, copywriting, service comparisons) — redirect to a general-purpose LLM. Do not waste context on non-technical work.

---

## 7. Autonomy

Work fully autonomously. Ask only when data is physically unknown: logins, passwords, IDs not present in the project.
