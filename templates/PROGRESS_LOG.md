# Progress Log — Key Decision Journal

---

## 📌 PINNED — Key decisions (read before any architectural change)

These decisions have already been tried, discussed, or have a non-obvious reason. Do not change without understanding the context.

| Decision | Reason | Where to look |
|---|---|---|
| **[Decision 1]** | [Why] | PROGRESS_LOG: "[entry name]" |
| **[Decision 2]** | [Why] | `[file.py]` → `[function]` |

---

## 🗃️ Archiving protocol

When the log grows beyond 40 entries: move entries older than 60 days to `PROGRESS_LOG_ARCHIVE.md`. The pinned block above — update on move (if the archived entry was in the table, keep the row with a note "see archive").

---

<!-- New entries go here, newest first -->

### [Decision name] (YYYY-MM-DD)
**Decision:** What exactly was done — specific, no fluff.
**Reason:** Why. What the problem was, what was tried before.
**DO NOT CHANGE because:** What breaks or recurs if reverted.
