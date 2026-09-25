---
description: Drain a Switchboard noise flood the right way — drop the flooding kind at the source first, then bulk-ack the backlog inline.
argument-hint: "[queue] (default: reviews)"
---

Clear a **noise flood** on the Switchboard queue `$1` (default `reviews`). Follow this order —
skipping step 1 turns this into a treadmill.

1. **Fix the source first.** Identify the flooding event kind (usually `workflow_run` CI events).
   - **Add a drop rule.** If you own the webhook (`list_webhooks` shows it), `add_webhook_rule`
     with `{drop: true}` matching that kind, placed **above** the rules that route real work
     (first match wins). Dry-run it with `test_webhook_rules` against stored deliveries first,
     and match the delivery's actual event header. The delivery is still recorded; it just stops
     becoming a todo. State what you added. (`create_webhook` / `rotate_webhook` cannot narrow —
     neither takes an event filter.)
   - **Or narrow at the producer**, with the forge's own event checkboxes. If it's a repo webhook
     you don't manage, you likely lack `admin:repo_hook`. Hand the human
     the exact fix: *repo Settings -> Webhooks -> the Switchboard hook -> uncheck "Workflow runs"
     and other pure-CI events; keep Pull requests, PR reviews, PR review comments, Issue
     comments, Issues.* Then continue to step 2 to clear the current backlog.

2. **Bulk-ack the current backlog inline, in THIS session.** Do NOT try to offload this to
   subagents — they don't inherit the Switchboard MCP tools. For each noise id: `claim` then
   `complete` with a triage result like
   `{"triage":"noise","reason":"CI/PR-lifecycle exhaust, no review action"}`.
   - Batch several claim calls then several complete calls per message to go faster; always
     complete an id you claimed within the same or the next message (leases are 300s).
   - **Context hygiene:** every claim returns the full ~15 KB webhook payload. Never
     quote, summarize, or repeat those payloads. Fire the calls and track only counts. Let the
     harness summarize older tool results.

3. **Preserve the real ones.** Do NOT ack genuinely actionable todos as noise. If you find any
   (a review requested, a human asking for something, failing CI on our PR), leave them and hand
   them to `/switchboard:work-next` — or at minimum surface them to the human before clearing.

4. Report: how many acked, what you narrowed at the source (or what the human still needs to do),
   and any actionable items you preserved.
