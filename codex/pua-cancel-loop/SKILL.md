---
name: pua-cancel-loop
description: "Cancel the active PUA loop and remove its state file."
license: MIT
---

# pua-cancel-loop

This is a Codex CLI alias for the Claude Code `/pua:cancel-loop` command.

Cancel the active PUA loop by cleaning loop state/worktree references and recording the event.

When this alias changes `~/.pua/config.json`, preserve unknown fields and create `~/.pua/` if missing. Do not claim completion without command/output evidence.
