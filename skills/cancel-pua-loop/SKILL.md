---
name: "cancel-pua-loop"
description: "Explicit command-style bridge for `/pua:cancel-pua-loop`. Use only when the user explicitly invokes `$pua:cancel-pua-loop` or asks for /pua:cancel-pua-loop."
license: MIT
---

# cancel-pua-loop

This skill is the Codex bridge for the Claude-style command `/pua:cancel-pua-loop`.

The behavior below is generated from `commands/cancel-pua-loop.md`. When it references other `/pua:...` commands, use the corresponding same-suffix skills under the `pua:` namespace.

<!-- AUTO-GENERATED: run `node scripts/generate-command-alias-skills.mjs` -->

# Cancel PUA Loop

1. Check if `.claude/pua-loop.local.md` exists:
   ```bash
   test -f .claude/pua-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"
   ```

2. **If NOT_FOUND**: Say "No active PUA loop found."

3. **If EXISTS**:
   - Read `.claude/pua-loop.local.md` to get the current `iteration:` value
   - Remove the file:
     ```bash
     rm .claude/pua-loop.local.md
     ```
   - Report: "PUA Loop cancelled (was at iteration N)"
