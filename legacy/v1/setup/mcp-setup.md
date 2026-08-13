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
claude mcp add --transport stdio codebase-memory-mcp --scope user -- codebase-memory-mcp
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
claude mcp add --transport stdio context7 --scope user -- npx -y @upstash/context7-mcp@latest
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

## 3. Auto-memory

Claude Code auto-memory is enabled by default. It automatically creates and maintains:

`~/.claude/projects/<project-id>/memory/MEMORY.md`

No manual setup is required.

Use `/memory` inside Claude Code to inspect, enable, or disable it.

Auto-memory is machine-local and is not shared through the repository.
See the [Claude Code memory documentation](https://docs.anthropic.com/en/docs/claude-code/memory).

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
