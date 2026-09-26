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
- **The Switchboard MCP server, as configuration** — `mcpServers.switchboard` in
  `.claude-plugin/plugin.json`, a remote Streamable HTTP server whose URL and bearer token come
  from your environment, plus a `channels` entry so an organization can allowlist it for push.
  See [Channels](#channels-doorbells-and-team-and-enterprise-orgs).
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

## Channels: doorbells, and Team and Enterprise orgs

The plugin declares the Switchboard server, so an admin has something to allowlist. It bundles
configuration only: no process, and no secret. Set two environment variables before launching
Claude Code:

| Variable | Value |
|---|---|
| `SWITCHBOARD_MCP_URL` | Your endpoint, for example `https://switchboard.stump.wtf/mcp/<slug>` |
| `SWITCHBOARD_MCP_TOKEN` | That endpoint's bearer credential (`sbk_…`) |

**If either is unset, the server does not connect, and nothing else breaks.** The skill and
commands still load, and the server is listed once as failed:

- `SWITCHBOARD_MCP_URL` unset: `claude mcp list` says
  `Failed to connect — Missing environment variables: SWITCHBOARD_MCP_URL`.
- `SWITCHBOARD_MCP_TOKEN` unset: the endpoint answers `HTTP 401` ("Server rejected the configured
  Authorization header"). The message does **not** name the variable, so check this one first.

If you already configure a `switchboard` server yourself (in `.mcp.json` or with
`claude mcp add`), leave these unset: your own server keeps working as before, and its tools keep
their `mcp__switchboard__*` names.

**Push needs the server named as a channel at launch.** Pick the form your account allows:

```bash
# Team or Enterprise org that allowlists this plugin (below)
claude --channels plugin:switchboard@claude-plugin-switchboard

# Everyone else: asks for confirmation at every launch
claude --dangerously-load-development-channels plugin:switchboard@claude-plugin-switchboard

# A server you configured yourself, not this plugin's
claude --dangerously-load-development-channels server:switchboard
```

A plugin-supplied server is scoped to the plugin. Its doorbells arrive as
`<channel source="plugin:switchboard:switchboard">`, and its tools are
`mcp__plugin_switchboard_switchboard__*`. Allow those up front, or a woken session stops at a
permission prompt: `--allowedTools mcp__plugin_switchboard_switchboard`.

**Admins** enable channels and approve this plugin in
[managed settings](https://code.claude.com/docs/en/settings). `allowedChannelPlugins` replaces
Anthropic's default allowlist, so list every channel plugin your org uses:

```json
{
  "channelsEnabled": true,
  "allowedChannelPlugins": [
    { "marketplace": "claude-plugin-switchboard", "plugin": "switchboard" }
  ]
}
```

`marketplace` is the name of the marketplace the plugin was installed from. It is
`claude-plugin-switchboard` for the install below; an internal marketplace that re-publishes the
plugin uses its own name.

Channels are a research preview, and the flag syntax may change. Checked against Anthropic's
[Channels guide](https://code.claude.com/docs/en/channels) and
[Channels reference](https://code.claude.com/docs/en/channels-reference) on 2026-09-25 (Claude
Code 2.1.280). Switchboard's side of the setup is on its
[connect page](https://switchboard.stump.wtf/docs/getting-started/connect-an-agent/).

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

## Reporting problems

Report problems with the skill or commands in
[GitHub Issues](https://github.com/stump-wtf/claude-plugin-switchboard/issues/new/choose). Bugs in
the Switchboard service go to [its tracker](https://github.com/stump-wtf/switchboard/issues), and
security problems follow [SECURITY.md](SECURITY.md).

## Releases

Every version is a tag. A change that bumps `version` in `.claude-plugin/plugin.json` is followed,
once it merges, by an annotated `vX.Y.Z` tag on that merge commit, pushed to the canonical
repository (the GitHub mirror picks it up on its next sync):

```bash
git fetch origin
git checkout origin/main
make release-check TAG=v0.3.0   # fails unless plugin.json says 0.3.0
git tag -a v0.3.0 -m v0.3.0
git push origin v0.3.0
```

CI runs the same `make release-check` on every `v*` tag. Pin a release tag, never a branch:
[Harness](https://github.com/stump-wtf/harness) pins this plugin by tag in its release manifest.

## Provenance

Distilled from a real session that triaged a 186-todo `reviews` queue flooded 71% with
`workflow_run` CI noise. The lessons here are the fixes to the mistakes made in that session.
