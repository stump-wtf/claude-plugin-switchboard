---
description: Claim the next actionable Switchboard todo and carry it through to complete or fail.
argument-hint: "[queue] (default: reviews)"
---

Work the next **actionable** todo on the Switchboard queue `$1` (default `reviews`).

1. `list_todos` (queue, `state: "pending"`, a `limit` of 200 or less) and pick the highest-value
   **actionable** todo per the `switchboard` skill's taxonomy. Skip noise and informational
   events — do not claim those here.
   - Triage is the point of listing first, so prefer this over `claim_next`, which takes whatever
     is next rather than letting you choose. (`claim_next` is the right call when you just want
     the next thing, or when several sessions share one endpoint.)
2. `claim` it (default lease, 300s). If the claim conflicts, another session owns it — stop and
   say so. `heartbeat` every couple of minutes, and before any slow step, for as long as you hold it.
3. Do the work the todo actually asks for (review the PR, answer the comment, fix the failing
   CI, etc.). For a PR, re-read its `state` / `merged` before any long step and stop if it has
   landed. If the todo carries a `work_order` or touches a PR, follow
   `skills/switchboard/references/queue-discipline.md` (work-order checks, fix the PR on its own
   branch, no self-merge, approve and merge as separate motions).
4. `complete` it with a `result` describing what you did — or, if you truly cannot finish it,
   `fail` it with a `result` explaining why (so it requeues rather than rotting under a stale
   lease). Never leave it claimed and abandoned.
5. Report what you did in one or two lines, then stop (one todo at a time).
