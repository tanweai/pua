---
name: pua:on
description: "Enable always-on PUA mode for future sessions. Use only when the user explicitly invokes `$pua:on` or asks to turn on always-on PUA behavior."
license: MIT
---

# PUA On

Enable PUA default mode:

1. Ensure `~/.pua/` exists.
2. Write `{\"always_on\": true}` to `~/.pua/config.json`.
3. Output confirmation: `> [PUA ON] 从现在起，每个新会话都会自动进入 PUA 模式。公司不养闲 Agent。`
