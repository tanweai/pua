---
name: pua:cancel-pua-loop
description: "Cancel the active PUA Loop. Use only when the user explicitly invokes `$pua:cancel-pua-loop` or asks to cancel the current loop."
license: MIT
---

# Cancel PUA Loop

1. Check if `.claude/pua-loop.local.md` exists:
   `test -f .claude/pua-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"`
2. If not found, say `No active PUA loop found.`
3. If found:
   - Read `.claude/pua-loop.local.md` to obtain the current `iteration:` value.
   - Remove the file: `rm .claude/pua-loop.local.md`
   - Report `PUA Loop cancelled (was at iteration N)`.
