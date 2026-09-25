# Getting doorbells

Read this when a session never wakes on a doorbell, when several doorbells arrive the moment a
session (re)connects, or when you need to hand an agent work by hand. The full setup is on
Switchboard's connect page: https://switchboard.stump.wtf/docs/getting-started/connect-an-agent/

## The channels flag — without it, every doorbell is silently dropped

Listing `switchboard` as an MCP server gives the session the **tools**. It does not give it
**push**. The client keeps the notification stream open either way, so the server logs
`mcp doorbell delivered` for every todo — and a client that was not told the server is a
*channel* discards each one. Neither side reports an error. This is the most common reason a
queue "never rings".

| Client | Opt in to push |
|---|---|
| Claude Code | `claude --dangerously-load-development-channels server:switchboard` |
| Crush (the `joestump-agent` fork) | `crush --channels server:switchboard`, or `"channel_enabled": true` on the server in `crush.json` |
| Any other MCP client | No push. Poll with `claim_next`. |

Things that look like push is broken but are not:

- **Claude Code asks for confirmation at every launch** with the development flag. An unattended
  worker sits at that prompt until someone answers it.
- **`claude -p` cannot be woken** — it exits when its turn ends. Scheduled or one-shot runs poll.
- **A woken session still needs permission to use the tools.** One that stops on a permission
  prompt for `claim` was rung and cannot act; allow them up front (`--allowedTools mcp__switchboard`).
- **A doorbell rings one session, not all of them.** If two different kinds of session both have
  switchboard channel-enabled on the same endpoint, doorbells land in whichever wins — often the
  one nobody is watching. Give push to exactly one kind of session.

## Ring-on-connect: three doorbells is not "three todos"

When a session opens (or reopens) its notification stream, Switchboard immediately rings it for
the **oldest 3** waiting todos in its scope, rather than waiting for the periodic re-ring sweep.
The same todo is rung this way at most **once a minute**, and these rings share the todo's overall
ring budget with the sweep — after that budget is spent, a todo stays pending and visible but is
no longer pushed.

So a session that reconnects and sees three doorbells has seen a *sample*, not the queue. Claim
each doorbell's `todo_id`, then keep going with `claim_next` until it answers `{"empty": true}`.
Never conclude the queue holds three todos because three rang.

## Handing an agent work by hand

A human operator with the `switchboard` CLI can mint a todo on an endpoint they own and ring its
doorbell in one step:

```
switchboard todo push ENDPOINT "look at PR 7"
switchboard todo push --payload @order.json ENDPOINT "look at PR 8"
```

It is the simplest way to give an agent a task, and the simplest end-to-end test of a new worker:
push one todo and watch the session wake, claim, and complete it. An agent has no MCP tool that
does this — todos otherwise arrive only as webhook deliveries.
