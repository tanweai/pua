---
name: pua-cancel-pua-loop
description: "Cancel the active PUA loop and remove its state file."
license: MIT
---

# pua-cancel-pua-loop

This is a Codex alias for the Claude Code `/pua:cancel-pua-loop` command.

Cancel the active PUA Loop by cleaning `~/.pua/loop-*.md`, compatible legacy `~/.claude/pua/loop-*.md`, local loop history state, and active-agent records. Record the teardown event before reporting completion.
