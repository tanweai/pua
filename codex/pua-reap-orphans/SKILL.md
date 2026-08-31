---
name: pua-reap-orphans
description: "Clean up stale PUA agent state."
license: MIT
---

# pua-reap-orphans

This is a Codex CLI alias for the Claude Code `/pua:reap-orphans` command.

Scan for stale PUA agent state and remove only confirmed orphan records. Report evidence.

When this alias changes `~/.pua/config.json`, preserve unknown fields and create `~/.pua/` if missing. Do not claim completion without command/output evidence.
