# claude-plugin-switchboard

A [Claude Code](https://claude.com/claude-code) plugin for working a
[Switchboard](https://joestump.github.io/switchboard/) durable webhook-to-todo queue
**correctly** — triage doorbell-driven todos, ack them one at a time, drain a flood without
running on a treadmill, and narrow the source when one event kind takes over.

Home: https://gitea.stump.rocks/stump.wtf/claude-plugin-switchboard ·
Mirror: https://github.com/stump-wtf/claude-plugin-switchboard

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

This plugin lives in a plugin marketplace / is added directly to a Claude Code project or
your user config. See the Claude Code plugin docs for the current install flow. The plugin
root is this repository (it contains `.claude-plugin/plugin.json`).

## Provenance

Distilled from a real session that triaged a 186-todo `reviews` queue flooded 71% with
`workflow_run` CI noise. The lessons here are the fixes to the mistakes made in that session.
