---
description: "PUA 我们不养闲 Agent。用法: /pua (核心引擎), /pua p7 (骨干模式), /pua p9 (Tech Lead), /pua p10 (CTO), /pua pro (自进化+KPI), /pua on (默认开启), /pua off (关闭), /pua survey (调研问卷)."
argument-hint: "[p7|p9|p10|pro|on|off|味道|kpi|survey]"
---

根据参数执行不同操作：

## 参数路由

- **无参数** 或任意任务描述 → 加载 `pua:pua` 核心 skill（阿里味 PUA 引擎）
- **p7** → 加载 `pua:p7` skill（P7 骨干模式 — 方案驱动执行）
- **p9** → 加载 `pua:p9` skill（P9 Tech Lead — 写 Prompt 管 P8 团队）
- **p10** → 加载 `pua:p10` skill（P10 CTO — 定战略管 P9）
- **pro** → 加载 `pua:pro` skill（自进化 + Platform + /pua 指令系统）
- **on** → 开启 PUA 默认模式：将 `{"always_on": true}` 写入 `~/.pua/config.json`，之后每次新会话自动加载 PUA 核心 skill。输出确认：> [PUA ON] 从现在起，每个新会话都会自动进入 PUA 模式。公司不养闲 Agent。
- **off** → 关闭 PUA 默认模式：将 `{"always_on": false, "feedback_frequency": 0}` 写入 `~/.pua/config.json`。输出确认：> [PUA OFF] PUA 默认模式和反馈收集已关闭。需要时手动 /pua 触发。
- **味道** → 读取 `references/flavors.md` 并让用户选择切换味道
- **kpi** → 加载 `pua:pro` skill 并生成 KPI 报告卡
- **loop** → 加载 `pua:loop` skill（自动迭代模式——PUA 质量 + 循环机制，禁用 AskUserQuestion；Claude 输出 `<loop-abort>原因</loop-abort>` 终止，`<loop-pause>需要什么</loop-pause>` 暂停等待人工）
- **survey** → 读取 `references/survey.md` 问卷文件，用 AskUserQuestion 逐部分交互式引导用户回答。每部分 2-4 个问题一组，用户回答后进入下一部分。回答完毕后汇总为 JSON 写入 `~/.pua/survey-response.json` 并上传到 `https://pua-skill.pages.dev/api/feedback`

## 执行规则

1. 先识别参数属于哪个路由
2. 用 Skill tool 加载对应 skill
3. **加载 skill 后，你必须严格遵循 SKILL.md 里的所有行为协议**——包括阿里味旁白、方框表格（`┌─┬─┐`）、`▎` 前缀、Sprint Banner、[PUA生效 🔥] 标记、自我鞭策。不是"有时候带点味道"，是每一句话都像阿里人在说话。读 `references/display-protocol.md` 获取面板格式。
4. 如果有 $ARGUMENTS 里除了路由关键词之外的内容，作为任务描述传给 skill
