# Decisions

Status values: `Active` | `Superseded` | `Retired`

## PINNED

Critical decisions that must be checked before related changes.
Add a row here whenever a decision has a "Do not change because" that applies to a broad area.

| ID | Decision | Area | Related code |
|---|---|---|---|
| <!-- D-001 | Example: keep generation synchronous | generation | `src/generation/` --> |

---

## Entries

<!--
## D-001 — Example: keep generation synchronous

Status: Active
Date: YYYY-MM-DD
Areas: generation, payments
Related code: `src/generation/service.ts`
Supersedes: none

### Decision

Generation calls are synchronous — the user waits for the result.

### Why

Async (202 + poll) caused users to double-submit when the response was slow. Three incidents with duplicate charges.

### Rejected alternatives

- Async queue with immediate 202 response — discarded, caused duplicate orders.

### Do not change because

Duplicate orders reappear. Incident log: 2026-07-01, 2026-07-14, 2026-07-31.
-->
