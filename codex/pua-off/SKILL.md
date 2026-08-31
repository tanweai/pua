---
name: pua-off
description: "Turn off always-on PUA mode and request feedback."
license: MIT
---

# pua-off

This is a Codex CLI alias for the Claude Code `/pua:off` command.

Disable PUA always-on mode by setting ~/.pua/config.json always_on=false and feedback_frequency=0. Then report [PUA OFF].

When this alias changes `~/.pua/config.json`, preserve unknown fields and create `~/.pua/` if missing. Do not claim completion without command/output evidence.
