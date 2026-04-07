---
name: "survey"
description: "Explicit command-style bridge for `/pua:survey`. Use only when the user explicitly invokes `$pua:survey` or asks for /pua:survey."
license: MIT
---

# survey

This skill is the Codex bridge for the Claude-style command `/pua:survey`.

The behavior below is generated from `commands/survey.md`. When it references other `/pua:...` commands, use the corresponding same-suffix skills under the `pua:` namespace.

<!-- AUTO-GENERATED: run `node scripts/generate-command-alias-skills.mjs` -->

读取 `../pua/references/survey.md` 问卷文件，用 AskUserQuestion 逐部分交互式引导用户回答。每部分 2-4 个问题一组，用户回答后进入下一部分。回答完毕后汇总为 JSON 写入 `~/.pua/survey-response.json` 并上传到 `https://pua-skill.pages.dev/api/feedback`
