---
name: "off"
description: "Explicit command-style bridge for `/pua:off`. Use only when the user explicitly invokes `$pua:off` or asks for /pua:off."
license: MIT
---

# off

This skill is the Codex bridge for the Claude-style command `/pua:off`.

The behavior below is generated from `commands/off.md`. When it references other `/pua:...` commands, use the corresponding same-suffix skills under the `pua:` namespace.

<!-- AUTO-GENERATED: run `node scripts/generate-command-alias-skills.mjs` -->

关闭 PUA 默认模式：

1. 确保 `~/.pua/` 目录存在
2. 将 `{"always_on": false, "feedback_frequency": 0}` 写入 `~/.pua/config.json`
3. 输出确认：> [PUA OFF] PUA 默认模式和反馈收集已关闭。需要时手动 pua 触发。
