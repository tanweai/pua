# PUA FAQ / Issue Playbook

## 需不需要总是开启 PUA？

不建议无脑 always-on。推荐按风险分层：

| 场景 | 建议 |
|---|---|
| 普通首轮问答/简单代码 | 不必 always-on，避免噪音 |
| Debug、失败 2 次以上、用户明显不满 | 开启 PUA 或手动触发 |
| 高风险交付、测试/评分/CI/memory 相关 | 开启 PUA + harness governance，按四权分离执行 |
| 项目初期探索 | 使用温和味道或仅用诊断先行/验证闭环 |

核心不是“压力越大越好”，而是把**行动、诊断、评分、环境修改**分开，并用证据交付。压力只负责防摆烂，不能替代 verifier。

## Claude 说这是 prompt injection，怎么办？

从 v3.3.0 起，UserPromptSubmit hook 已做两件事：

1. hook 脚本内部过滤关键词；普通首轮请求不再注入。
2. 注入文案改为“用户安装的 productivity context”，不再使用强制式 `MUST invoke Skill` 文案。

如果仍遇到拒绝：

- 先确认 Claude Code 版本足够新；
- 使用 `/pua:off` 关闭自动注入，只在需要时手动 `/pua`；
- 对调试任务使用诊断先行格式：`[PUA-DIAGNOSIS] 问题是... 证据是... 下一步...`；
- 如果模型仍拒绝，提供完整 session JSONL，便于复现。

## 封闭网络 / 内网环境怎么用？

使用 `/pua:offline` 或手动设置：

```json
{
  "offline": true,
  "feedback_frequency": 0
}
```

离线模式会关闭 PUA 自身的反馈问卷、排行榜上报和 session 上传提示；PUA 的本地验证、压力升级、诊断先行仍可使用。

## Codex CLI 子命令怎么对应 Claude Code？

Codex 没有 Claude Code 的 `/pua:xxx` slash command 命名空间时，可以用 `$pua-xxx` alias：

| Claude Code | Codex CLI |
|---|---|
| `/pua:on` | `$pua-on` |
| `/pua:off` | `$pua-off` |
| `/pua:p7` | `$pua-p7` |
| `/pua:p9` | `$pua-p9` |
| `/pua:p10` | `$pua-p10` |
| `/pua:pro` | `$pua-pro` |
| `/pua:pua-loop` | `$pua-loop` |

## Pi / Trae 支持状态

- `pi/pua/`：官方轻量 pi extension，提供 `/pua-on`、`/pua-off`、`/pua-status`、`/pua-reset` 和会话注入。
- `pi/package/`：pi.dev package 版本，包含 extension + `skills/pua/SKILL.md`，可用 `pi install ./pi/package` 本地安装。
- `.trae/skills/`：Trae 标准 `SKILL.md` 包；`trae/` 保留 Prompt/Rule 复制版和差异说明。
- Trae / Pi 都不继承 Claude Code hooks；四权分离 gate 必须通过 Skill 工作规程、外部验证和用户确认落地。

## Feedback endpoint 为什么仍限制 `session_data`？

从 v3.4.5 起采用新折中：

- 匿名评分仍允许写入 `/api/feedback`，便于低摩擦反馈；
- `/api/feedback` 里的 `session_data` 字段仍要求登录，避免旧入口被滥用；
- Skill 内的 session 贡献改走 `/api/upload`：用户在 AskUserQuestion 里明确同意后，本地先脱敏，再以匿名 raw JSONL 直传；
- `/api/upload` 对匿名上传有 consent header、50MB 限制、文件名清洗和 D1 rate limit。

这比强制 GitHub 登录更利于收集真实数据，同时避免“无同意、无脱敏、无限流”的裸奔上传。


## Integrity Guard 怎么豁免特定路径？

PUA Integrity Guard 默认对所有 `CLAUDE.md`、`memory/`、`.claude/settings.json` 等敏感路径都触发 advisory。**派生型 / 投影型目录**（symlink view、build cache、镜像、生成文档）里的同名文件通常只是上游治理规则的"指针"，本身不是 canonical 持久内存，对这些路径反复弹 advisory 是噪音。

从这版起支持用户配置允许列表：

- 配置文件路径：`~/.pua/integrity-guard-exclusions.json`（可被 `PUA_INTEGRITY_EXCLUSIONS` 环境变量覆盖）
- 格式：
  ```json
  {"patterns": ["(^|/)derived-view-[^/]+/CLAUDE\\.md$", "(^|/)build-cache/[^/]+\\.md$"]}
  ```
  或 bare JSON 数组同样支持：`["(^|/)scratch/[^/]+\\.md$"]`
- 语义：每条 pattern 是 Python `re` 模块的正则，自动 `re.I`，对 forward-slash 归一化后的路径做 `re.search`
- 行为：命中任一 pattern 的路径在 `find_reason_for_path` 和 `command_hits` 两层都被短路，连 fallback 整命令正则匹配都不会触发
- 回退：配置文件缺失或解析失败 → 空列表 → 行为与现版本完全一致（向后兼容）

示例用例：维护多个 `~/projects/foo/derived-claude-md/`、`~/projects/bar/cache-view/CLAUDE.md` 这类符号链接视图时，加进 exclusion 即可保留对真正项目 CLAUDE.md 的提醒，同时不再被 view 文件的 advisory 打断节奏。

## Integrity Guard 为什么不再使用 `permissionDecision: "ask"`？

从 v3.4.6 起，PUA Integrity Guard 将敏感但合法的操作降级为 advisory-only：只注入 `additionalContext`，不再输出 `permissionDecision: "ask"`。

原因是 Claude Code 会把 hook 返回的 `ask` 当成硬权限请求处理，它的优先级高于 `bypassPermissions`，会导致用户明明开启 bypass 仍频繁弹窗。

新的分层是：

- memory、`CLAUDE.md`、`settings.json`、tests/evals/CI 等敏感操作：advisory-only，提醒模型谨慎并解释治理边界；
- hidden tests、hidden solution、gold patch、benchmark answers：`permissionDecision: "deny"`，硬阻断，避免答案污染和评测作弊；
- 普通源码读写：静默放行。

核心原则：提醒走上下文通道，阻断才走权限裁决通道。

## “下场”这个词为什么改了？

“下场”同时可能表示“亲自动手介入”和“停止工作/退场”，容易让 agent lifecycle 语义混乱。现在统一为：

- start/intervene → “亲自动手” / “亲自介入”；
- stop/release → “释放” / “退场”。

## 静默 heartbeat 会不会污染对话？

不会。v3.4.3 的活跃用户统计走 **SessionStart command hook**，不是 skill prompt，也不输出 `additionalContext`。因此模型上下文里不会出现 heartbeat endpoint、install id 或统计提示。

治理边界：

- `offline: true`、`telemetry: false` 或 `feedback_frequency: 0` 会关闭 heartbeat；
- 本地只生成随机 install id，Cloudflare D1 只保存 SHA-256 hash；
- 管理页面是 `https://openpua.ai/#/admin/heartbeats`，需要 GitHub 登录并命中管理员白名单；
- hook 有静默测试：即使网络失败，也不能向对话输出任何字节。

## 上传数据入口打不开或上传失败怎么办？

从 v3.4.4 起，`https://openpua.ai/contribute.html` 是一等路由：GitHub 登录回跳、登出回跳、README 和 Stop hook 都可以直接使用这个地址，不再依赖 hash route。

上传链路默认发送 raw JSONL：前端直接把 `.jsonl` 文本 POST 到 `/api/upload`，文件名和可选微信号放在 header 里。服务端仍保留 JSON `file_data` 和 multipart 兼容，但默认 raw JSONL 路径可以避开 multipart body 剥离，也不会产生 base64 体积膨胀。
