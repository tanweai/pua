---
name: pua
description: "Legacy compatibility shim for older Codex installs that still link `~/.codex/skills/pua` to `~/.codex/pua/codex/pua`. Keeps the core PUA skill working while users migrate to the `skills/*` layout for namespaced subcommands."
license: MIT
---

# Legacy Codex Compatibility Shim

This path is kept for users who previously linked `~/.codex/skills/pua` to `~/.codex/pua/codex/pua`.

Load and follow the canonical skill at `../../skills/pua/SKILL.md` exactly.

For new installs, use the shared `skills/*` layout documented in `.codex/INSTALL.md`.
