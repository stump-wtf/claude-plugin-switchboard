---
description: Triage a Switchboard queue — bucket pending todos into actionable / informational / noise and propose a plan (read-only).
argument-hint: "[queue] (default: reviews)"
---

Triage the Switchboard queue `$1` (if `$1` is empty, use `reviews`). Do NOT ack anything yet —
this is read-only triage.

1. Call `list_todos` with `queue` set to the target, `state: "pending"`, and `limit: 200`.
   - If the result overflows and the harness spills it to a file, do NOT read the file back —
     query it with `jq` instead (e.g. bucket by `.kind`, pull `.id`/`.title`).
2. Bucket every pending todo into **actionable / informational / noise** using the taxonomy in
   the `switchboard` skill. Call out in particular:
   - any **`workflow_run`** or other CI events (noise),
   - PR-lifecycle churn — `labeled`, `synchronize`, `closed` (mostly informational/noise),
   - genuinely actionable items: a review requested, a human comment asking for something,
     **failing CI on one of our PRs**.
3. If one event kind is clearly flooding the queue, say so and name the **source fix** (narrow
   the webhook — with the exact steps if it's a repo webhook you don't manage).
4. Report a compact plan: counts per bucket, the handful of actionable items (with links), and
   a recommended next action (`/switchboard:work-next` for the real work,
   `/switchboard:drain` for the noise).
