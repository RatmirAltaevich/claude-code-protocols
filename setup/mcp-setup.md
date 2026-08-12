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

The recommended way is via the Claude Code CLI:

```bash
claude mcp add codebase-memory-mcp
```

Alternatively, add manually to `~/.claude.json` under `mcpServers`:

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
index_repository(project="my-project", root_path="/absolute/path/to/project")
```

Add your project to `global/CLAUDE.md` → "Indexed projects" table after indexing.

### Key tools

| Tool | When to use |
|---|---|
| `search_graph(name_pattern="...")` | Find function/class by name |
| `search_graph(query="...")` | Find by behavior description |
| `get_code_snippet(qualified_name="...")` | Read exact source of a symbol |
| `trace_path(function_name="...")` | Call chain up/down |
| `search_code(pattern="...")` | Text pattern search (graph-augmented grep) |
| `get_architecture(project="...")` | Project structure overview |

---

## 2. Context7

Fetches current library documentation indexed from official sources.

### Install

```bash
npm install -g @upstash/context7-mcp
```

### Configure

```bash
claude mcp add context7 -- npx @upstash/context7-mcp
```

Or manually in `~/.claude.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["@upstash/context7-mcp"]
    }
  }
}
```

### Usage

```
resolve-library-id(libraryName="aiogram")
get-library-docs(context7CompatibleLibraryID="/aiogram/aiogram", topic="FSM states")
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

After setup, confirm everything works in a Claude Code session:

```
# Should return your indexed project's nodes
search_graph(name_pattern=".*", project="my-project", limit=5)

# Should return a library ID
resolve-library-id(libraryName="requests")
```
