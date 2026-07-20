# Proposal: server-authored MCP prompts for Switchboard

Status: **proposal** · Owner: TBD · Target: the Switchboard MCP server (https://github.com/joestump/switchboard)

## Why

MCP lets a server ship reusable, **server-authored prompt templates** (`prompts/list`,
`prompts/get`). Clients surface them as slash commands, and agent runtimes can now discover and
invoke them as tools (see the Crush work that exposed MCP prompts to the agent —
joestump-agent/crush #162, landed in #170: `list_mcp_prompts` / `call_mcp_prompt`).

Today the correct way to work a Switchboard queue lives in *client-side* skills and slash
commands (this plugin). That is good for Claude Code, but it means every other client re-invents
the workflow, and the guidance can drift from the server's actual semantics. Moving the core
flows into **server-authored prompts** makes them:

- **client-agnostic** — any MCP client (or agent via `call_mcp_prompt`) gets them for free;
- **authoritative** — they live next to the tools they drive, so they stay correct as the API
  evolves;
- **safe by construction** — the server can bake in the guardrails (tight `list_todos` filters,
  "don't echo payloads", "narrow the source, don't treadmill") rather than hoping each client
  remembers.

This plugin's skill + commands become the *reference implementation*; the server prompts become
the portable version.

## Proposed prompts

Prompt names use the MCP convention (snake_case). Arguments follow `prompts/get`.

### 1. `triage_queue`

Bucket a queue's pending todos into actionable / informational / noise and propose a plan.
Read-only (acks nothing).

Arguments:
| name | required | description |
|---|---|---|
| `queue` | yes | queue to triage |
| `limit` | no | max todos to inspect (default 200) |

Rendered prompt guides the agent to: call `list_todos(queue, state="pending", limit)`; if the
result is huge, bucket by `kind` without echoing payloads; classify with the actionable /
informational / noise taxonomy; flag any single event kind that dominates and name the source
fix; return counts + the actionable shortlist.

### 2. `drain_noise`

Clear a noise flood correctly: narrow the source first, then bulk-ack the backlog.

Arguments:
| name | required | description |
|---|---|---|
| `queue` | yes | queue to drain |
| `dry_run` | no | if true, report the plan and counts but ack nothing |

Rendered prompt: identify the flooding kind; if the endpoint manages the webhook, narrow it via
`create_webhook`/`rotate_webhook` and report the change; else emit the exact repo-webhook
remediation for a human; then, unless `dry_run`, bulk `claim`->`complete` the noise with a triage
`result`, **without echoing the ~15 KB payloads**, tracking only counts; never ack genuinely
actionable todos.

### 3. `work_next_todo`

Claim the single highest-value actionable todo and carry it to `complete`/`fail`.

Arguments:
| name | required | description |
|---|---|---|
| `queue` | yes | queue to pull from |
| `kind` | no | restrict to a todo kind (e.g. `pull_request`) |

Rendered prompt enforces the one-at-a-time discipline: pick one actionable todo, `claim`,
`heartbeat` if long, do the work, `complete` with a result (or `fail` with a reason), stop.

## Guardrails the server should encode in every prompt

These are the exact traps that bite agents on busy queues (learned in production):

1. **Tight `list_todos` filters always.** Never render a prompt that lists a queue without
   `queue` + `state` + a `limit`; the unfiltered call blows client context windows.
2. **Never echo webhook payloads.** `claim`/`complete` each return the full upstream payload;
   prompts must instruct "track counts, do not quote payloads".
3. **The drain runs where the tools are.** Prompts must not tell the agent to offload the drain
   to subagents — in at least the Claude Code runtime, subagents don't inherit the Switchboard
   MCP tools.
4. **Fix the source, don't treadmill.** The drain prompt must lead with narrowing the webhook.

## Open questions

- Should `drain_noise` refuse to run if the source webhook is not narrowable by this endpoint,
  or proceed with a one-time clear + a warning? (Proposed: proceed + warn.)
- Prompt vs. tool: some of this could instead be a `bulk_complete` **tool** (accepting an array
  of ids + a shared result), which would also fix the payload-echo problem at the protocol level.
  Worth considering alongside the prompts — arguably the higher-leverage fix.
