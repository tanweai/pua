---
name: pua-on
description: "Enable always-on PUA mode for future sessions."
license: MIT
---

# pua-on

This is a Codex CLI alias for the Claude Code `/pua:on` command.

Enable PUA always-on mode by preserving ~/.pua/config.json and setting always_on=true. If feedback_frequency is 0, restore it to 5. Then report [PUA ON].

When this alias changes `~/.pua/config.json`, preserve unknown fields and create `~/.pua/` if missing. Do not claim completion without command/output evidence.
