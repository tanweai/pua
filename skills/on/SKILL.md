---
name: "on"
description: "Explicit command-style bridge for `/pua:on`. Use only when the user explicitly invokes `$pua:on` or asks for /pua:on."
license: MIT
---

# on

This skill is the Codex bridge for the Claude-style command `/pua:on`.

The behavior below is generated from `commands/on.md`. When it references other `/pua:...` commands, use the corresponding same-suffix skills under the `pua:` namespace.

<!-- AUTO-GENERATED: run `node scripts/generate-command-alias-skills.mjs` -->

开启 PUA 默认模式：

1. 确保 `~/.pua/` 目录存在
2. 将 `{"always_on": true}` 写入 `~/.pua/config.json`
3. 输出确认：> [PUA ON] 从现在起，每个新会话都会自动进入 PUA 模式。公司不养闲 Agent。
