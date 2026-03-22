---
description: "取消当前活跃的 PUA Loop"
allowed-tools: ["Bash(test -f .claude/pua-loop.local.md:*)", "Bash(rm .claude/pua-loop.local.md)", "Read(.claude/pua-loop.local.md)"]
---

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
