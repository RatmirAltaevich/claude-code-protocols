# Decisions

Status values: `Active` | `Superseded` | `Retired`

---

## D-001 — Locked supabase-py at 1.x

Status: Active
Date: 2026-08-01
Related code: `requirements.txt`

### Decision

`supabase-py` is pinned to `1.x` and must not be updated.

### Why

Version 2.x rewrites the client interface. Migration requires updating every DB call in the project. Risk too high before launch.

### Do not change because

Updating to 2.x breaks all `supabase.table(...).select(...)` calls. The httpx version conflict also breaks `google-genai`.
