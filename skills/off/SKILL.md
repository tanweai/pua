---
name: pua:off
description: "Disable always-on PUA mode and feedback collection. Use only when the user explicitly invokes `$pua:off` or asks to turn off always-on PUA behavior."
license: MIT
---

# PUA Off

Disable PUA default mode:

1. Ensure `~/.pua/` exists.
2. Write `{\"always_on\": false, \"feedback_frequency\": 0}` to `~/.pua/config.json`.
3. Output confirmation: `> [PUA OFF] PUA 默认模式和反馈收集已关闭。需要时手动 /pua:pua 触发。`
