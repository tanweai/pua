---
description: "PUA for Codex. Use `/prompts:pua` as the Codex fallback entrypoint, or invoke installed skills directly with `$pua` and `$pua:<subcommand>`."
argument-hint: "[subcommand|task]"
---

Codex routing for PUA:

- No argument or a freeform task -> load `pua` (legacy Codex core entrypoint)
- If the first argument matches an installed namespaced skill, route to `pua:<first-argument>`.
- Compatibility alias: `loop` -> load `pua:pua-loop`.
- Otherwise, keep using `pua` and treat the rest as the task text.

When a routed skill is loaded, follow that skill exactly as written.
