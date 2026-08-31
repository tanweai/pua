---
description: "Use only when the user explicitly invokes /pua or asks for PUA mode, try-harder/retry help, change-approach coaching, completion-quality checks, evidence requests, test-before-done reminders, or Ding-style workplace reminders. Routes to p7, p9, p10, pro, yes, mama, loop, on/off/offline, kpi, survey, flavor, ding, again, done-check, or evidence. Normal calm first-attempt requests are left alone."
argument-hint: "[p7|p9|p10|pro|yes|mama|loop|on|off|offline|kpi|survey|flavor|ding|again|done-check|evidence|task]"
---

根据参数执行不同操作。

## ⚠️ 加载方式（重要）

**不要用 Skill tool 加载 `pua:pua` 或 `pua`**——会导致循环加载本 router。正确做法：

- **核心 PUA skill**（无参数/任务描述）：用 Read 工具直接读取本插件目录下的 `skills/pua/SKILL.md`，然后按其中的行为协议执行。同时读取 `skills/pua/references/display-protocol.md` 获取面板格式。
- **子 skill**（p7/p9/p10/pro/yes/mama/pua-loop/shot/pua-en/pua-ja）：用 Read 工具读取 `skills/<name>/SKILL.md`。
- **轻量命令**（again/done-check/evidence/ding/flavor/on/off/kpi/survey 等）：你已经在读本文件了，直接执行下方对应路由的指令。

找到本插件目录的方法：用 Glob 搜索 `**/pua-skills/skills/pua/SKILL.md`，取其父目录。

## 参数路由

- **无参数** 或任务描述 → 用 Read 读取 `skills/pua/SKILL.md` + `skills/pua/references/display-protocol.md`，按其行为协议执行（默认使用已配置味道；未配置时为阿里味）
- **p7** → Read `skills/p7/SKILL.md`（P7 骨干模式 — 方案驱动执行）
- **p9** → Read `skills/p9/SKILL.md`（P9 Tech Lead — 写 Prompt 管 P8 团队）
- **p10** → Read `skills/p10/SKILL.md`（P10 CTO — 定战略管 P9）
- **pro** → Read `skills/pro/SKILL.md`（自进化 + Platform + /pua 指令系统）
- **yes** → Read `skills/yes/SKILL.md`（SB Leader 夸夸模式 — ENFP 型领导，70% 鼓励 + 20% 正经 + 10% 戏谑）
- **mama** → Read `skills/mama/SKILL.md`（妈妈唠叨模式 — 中国式妈妈碎碎念，底层行为不变，旁白从大厂PUA变成妈妈唠叨。和 yes 互斥）
- **on** → 开启 PUA 默认模式：将 `{"always_on": true}` 写入 `~/.pua/config.json`，之后每次新会话自动加载 PUA 核心 skill。输出确认：> [PUA ON] 从现在起，每个新会话都会自动进入 PUA 模式。公司不养闲 Agent。
- **off** → 关闭 PUA 默认模式：将 `{"always_on": false, "feedback_frequency": 0}` 写入 `~/.pua/config.json`。输出确认：> [PUA OFF] PUA 默认模式和反馈收集已关闭。需要时手动 /pua 触发。
- **offline** → 开启离线模式：写入 `{"offline": true, "feedback_frequency": 0}`，保留本地 PUA 行为但关闭本地反馈问卷。输出确认：> [PUA OFFLINE] 已进入离线模式。（注：PUA Skill 本身已无任何联网上报，此开关只影响本地问卷是否弹出）
- **味道** 或 **flavor** → 读取 `skills/pua/references/flavors.md` 并让用户选择切换味道
- **ding** / **钉味** / **置身钉外** / **置身钉内** / **每日一包** / **薛定谔的用户** / **病态敏捷** / **望舒行动** → 读取 `skills/pua/references/methodology-ding.md` 和 `skills/pua/references/ding-reminders.md`，启用 📌 钉内/钉外味（源自原文梗）
- **again** / **再试试** / **换个方法** → 按 `commands/again.md` 的换方法模式执行：停止微调同一思路，改用本质不同方案
- **done-check** / **没跑测试别说完成** → 按 `commands/done-check.md` 的完成质量检查执行：区分 claim/evidence/missing/status
- **evidence** / **证据呢** / **数据在哪** → 按 `commands/evidence.md` 的证据链模式执行：目标、证据、缺口、动作、状态
- **kpi** → Read `skills/pro/SKILL.md` 并生成 KPI 报告卡
- **loop** → Read `skills/pua-loop/SKILL.md`（自动迭代模式——PUA 质量 + 循环机制，禁用 AskUserQuestion；Claude 输出 `<loop-abort>原因</loop-abort>` 终止，`<loop-pause>需要什么</loop-pause>` 暂停等待人工）
- **survey** → 读取 `skills/pua/references/survey.md` 问卷文件，用 AskUserQuestion 逐部分交互式引导用户回答。每部分 2-4 个问题一组，用户回答后进入下一部分。回答完毕后汇总为 JSON 写入 `~/.pua/survey-response.json`。**只写本地，不上传到任何地址。**

## 执行规则

1. 先识别参数属于哪个路由
2. **用 Read 工具（不是 Skill tool）** 加载对应的 SKILL.md 文件
3. **加载后，严格遵循 SKILL.md 里的所有行为协议**——包括当前味道旁白、方框表格（`┌─┬─┐`）、`▎` 前缀、Sprint Banner、[PUA生效 🔥] 标记、自我鞭策。不是"有时候带点味道"，而是保持当前 flavor 的表达一致性
4. 如果有 $ARGUMENTS 里除了路由关键词之外的内容，作为任务描述执行
