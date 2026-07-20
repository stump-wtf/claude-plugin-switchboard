---
description: Claim the next actionable Switchboard todo and carry it through to complete or fail.
argument-hint: "[queue] (default: reviews)"
---

Work the next **actionable** todo on the Switchboard queue `$1` (default `reviews`).

1. `list_todos` (queue, `state: "pending"`, small `limit`) and pick the highest-value
   **actionable** todo per the `switchboard` skill's taxonomy. Skip noise and informational
   events — do not claim those here.
2. `claim` it (default lease). If the work is long-running, `heartbeat` before the lease lapses.
3. Do the work the todo actually asks for (review the PR, answer the comment, fix the failing
   CI, etc.).
4. `complete` it with a `result` describing what you did — or, if you truly cannot finish it,
   `fail` it with a `result` explaining why (so it requeues rather than rotting under a stale
   lease). Never leave it claimed and abandoned.
5. Report what you did in one or two lines, then stop (one todo at a time).
