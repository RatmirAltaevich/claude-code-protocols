# MCP Setup Guide

Two MCP servers power the code navigation protocol: **codebase-memory-mcp** (code graph) and **Context7** (library docs).

---

## 1. codebase-memory-mcp

Builds a navigable graph of your codebase — functions, classes, imports, call chains. Replaces grep/find for code discovery.

### Install

```bash
npm install -g codebase-memory-mcp
```

### Configure in Claude Code

Add to `~/.claude/settings.json` (or via `/mcp` in Claude Code):

```json
{
  "mcpServers": {
    "codebase-memory-mcp": {
      "command": "codebase-memory-mcp",
      "args": []
    }
  }
}
```

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

Fetches up-to-date documentation for any library — directly from official sources, not from the model's training data.

### Install

```bash
npm install -g @context7/mcp
```

### Configure

```json
{
  "mcpServers": {
    "context7": {
      "command": "context7-mcp",
      "args": []
    }
  }
}
```

### Usage

```
resolve-library-id(libraryName="aiogram")
get-library-docs(context7CompatibleLibraryID="/aiogram/aiogram", topic="FSM states")
```

Always use before writing code with any external library, especially ones with breaking changes between major versions.

---

## 3. Auto-memory (optional but recommended)

Claude Code supports a file-based memory system at `~/.claude/projects/<project-id>/memory/`. Combined with `MEMORY.md` as an index, this gives Claude persistent context across sessions.

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

# Should return library documentation
resolve-library-id(libraryName="requests")
```
