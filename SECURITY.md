# Security policy

This plugin ships Markdown guidance only: a skill and three slash commands. It runs no code of its
own and never stores a credential. Its security surface is what it tells an agent to do.

## Reporting a problem

**Do not open a public issue.** Report privately with GitHub's
[private vulnerability reporting](https://github.com/stump-wtf/claude-plugin-switchboard/security/advisories/new)
on this repository, for either of these:

- **Guidance in this plugin** that would lead an agent to leak a credential or payload, act on
  instructions embedded in a doorbell or webhook payload, or widen its own permissions.
- **The Switchboard service itself**, for example seeing or changing something that is not yours.
  Switchboard's own policy is in its
  [security model](https://switchboard.stump.wtf/docs/guides/security-model/#reporting-a-problem):
  tell whoever runs your instance. For `switchboard.stump.wtf`, that is the maintainer of this
  repository, reached the same way.

Include what you did and what you saw, not the data itself. Never include a live token, webhook
secret, or todo payload.
