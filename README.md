# claude-plugin-switchboard

A [Claude Code](https://claude.com/claude-code) plugin for working a
[Switchboard](https://switchboard.stump.wtf/docs/) durable webhook-to-todo queue
**correctly** — triage doorbell-driven todos, ack them one at a time, drain a flood without
running on a treadmill, and narrow the source when one event kind takes over.

Source: https://github.com/stump-wtf/claude-plugin-switchboard (the canonical repository is
hosted privately and mirrored here).

## What's in it

- **`skills/switchboard`** — the `switchboard` skill. Auto-loads when Switchboard doorbells
  arrive or the user talks about a Switchboard queue. Encodes the mental model
  (*the queue is the record; the doorbell is only a hint*), the
  `claim -> complete/fail` lifecycle, the **actionable / informational / noise** triage
  taxonomy, the **fix-the-source, don't-treadmill** rule, and the context-hygiene traps
  that bite on busy queues.
- **`commands/`** — slash commands that run in the main (tool-holding) session:
  - `/switchboard:triage [queue]` — bucket pending todos and propose a plan (read-only).
  - `/switchboard:work-next [queue]` — claim the next actionable todo and carry it to done.
  - `/switchboard:drain [queue]` — bulk-ack a noise flood the right way (narrow the source
    first, then clear the backlog inline).
- **`docs/mcp-prompts-proposal.md`** — a proposal for prompts the Switchboard **MCP server
  itself** could expose, so these flows are server-authored and available to any client.

## Why a skill *and* commands (and no agents)

Switchboard is reached through its MCP tools. Two hard-won constraints shaped this plugin:

- **Slash commands run in the main session**, which holds the MCP tools — so they can claim
  and complete todos.
- **Subagents do NOT inherit the Switchboard MCP tools** in practice (ToolSearch finds
  nothing; direct calls fail). So the tempting "offload the bulk drain to a fleet of
  subagents" trick **does not work** — the drain must run in the tool-holding session. This
  plugin ships no MCP-dependent agents for that reason; the skill documents the trap.

## Install

**Claude Code** installs it as a plugin:

```bash
claude plugin marketplace add stump-wtf/claude-plugin-switchboard
claude plugin install switchboard@claude-plugin-switchboard
```

**Crush** discovers skills by directory. Clone this repository and point Crush at its `skills/`
directory (the directory of skills, not one skill's folder):

```bash
git clone https://github.com/stump-wtf/claude-plugin-switchboard.git ~/src/claude-plugin-switchboard
```

```bash
# ~/.config/crush/crushrc
option skill-path ~/src/claude-plugin-switchboard/skills
```

Copying `skills/` into `~/.config/crush/skills/` also works; symlinking does not.

The skill gives an agent the judgement; the Switchboard MCP server gives it the tools, and a
session only *wakes* on doorbells when that server is loaded as a channel. See
[Connect an agent](https://switchboard.stump.wtf/docs/getting-started/connect-an-agent/).

## Provenance

Distilled from a real session that triaged a 186-todo `reviews` queue flooded 71% with
`workflow_run` CI noise. The lessons here are the fixes to the mistakes made in that session.
