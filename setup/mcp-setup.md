# MCP Setup Guide

Two MCP servers power the code navigation protocol: **codebase-memory-mcp** (code graph) and **Context7** (library docs).

---

## 1. codebase-memory-mcp

Builds a navigable graph of your codebase — functions, classes, imports, call chains.

### Install

```bash
npm install -g codebase-memory-mcp
```

### Configure in Claude Code

```bash
claude mcp add --transport stdio codebase-memory-mcp -- codebase-memory-mcp
```

Or manually in `~/.claude.json`:

```json
{
  "mcpServers": {
    "codebase-memory-mcp": {
      "command": "codebase-memory-mcp"
    }
  }
}
```

> **Note:** Claude Code settings file locations follow the [official Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/settings). User-level MCP config lives in `~/.claude.json`; project-level in `.mcp.json` at the project root.

### Index your project

Run once at the start, then re-run after major refactors:

```
index_repository(repo_path="/absolute/path/to/project", name="my-project")
```

Add your project to `global/CLAUDE.md` → "Indexed projects" table after indexing.

### Key tools

| Tool | When to use |
|---|---|
| `search_graph(name_pattern="...")` | Find function/class by name |
| `search_graph(query="...")` | Find by behavior description |
| `get_code_snippet(qualified_name="...")` | Read exact source of a symbol |
| `trace_path(function_name="...", direction="inbound")` | Who calls a function |
| `trace_path(function_name="...", direction="outbound")` | What a function calls |
| `search_code(pattern="...")` | Text pattern search (graph-augmented grep) |
| `get_architecture(project="...")` | Project structure overview |

---

## 2. Context7

Fetches current library documentation from the Context7 index. Sources may be official or community-maintained, so critical information should be verified.

### Configure

```bash
claude mcp add --transport stdio context7 -- npx -y @upstash/context7-mcp@latest
```

Or manually in `~/.claude.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

### Usage

```
resolve-library-id(libraryName="aiogram", query="FSM states in aiogram")
query-docs(libraryId="/aiogram/aiogram", query="FSM states")
```

Use before writing code with any library that has frequent breaking changes between major versions.

---

## 3. Auto-memory (optional but recommended)

Claude Code has a built-in file-based memory system at `~/.claude/projects/<project-id>/memory/`. See [Claude Code memory docs](https://docs.anthropic.com/en/docs/claude-code/memory) for details.

The global `CLAUDE.md` in this repo uses this system. To enable:

1. Claude Code creates the memory directory automatically
2. Add a `MEMORY.md` index file with entries pointing to memory files
3. Claude will read and update memory files during sessions

No installation needed — it's built into Claude Code.

---

## Verification

After setup, confirm servers appear as connected:

```bash
claude mcp list
```

Both `codebase-memory-mcp` and `context7` should show status `connected`.

Then confirm functionality in a Claude Code session:

```
# Should return your indexed project's nodes
search_graph(name_pattern=".*", project="my-project", limit=5)

# Should return a library ID
resolve-library-id(libraryName="requests", query="http get request")
```
