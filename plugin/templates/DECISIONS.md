# Decisions

Active architectural decisions and the reasoning behind them.

Status values: `Active` | `Superseded` | `Retired`

---

<!--
## D-001 — Example: kept synchronous generation

Status: Active
Date: YYYY-MM-DD
Related code: `src/generation/service.ts`

### Decision

Generation calls are synchronous — the user waits for the result before the API returns.

### Why

Async (202 + poll) caused users to double-submit when the response was slow. Three incidents with duplicate charges.

### Do not change because

Duplicate orders reappear. Incident log: 2026-07-01, 2026-07-14, 2026-07-31.
-->
