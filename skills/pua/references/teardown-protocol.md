# PUA Teardown Protocol — Agent 生命周期释放协议

> **当职业球队里某位球员已经打完自己那场比赛，你必须让他下场。继续让他站在场上只会拖垮全队节奏。**
> — Netflix Keeper Test 推论

PUA v3 之前的协议只覆盖 agent 生命周期的前 4 步（Define → Spawn → Monitor → Accept），缺后 3 步（**Release → Cleanup → Orphan handling**）。这会导致：

- 验收通过的 P8 不被释放 → 上下文堆满已完成的 agent
- TeamCreate 的 tmux pane 无人关闭 → 资源常驻
- worktree 隔离的 agent 完成后留下孤儿代码副本 → 磁盘+context 浪费
- 会话 auto-compact 后 orphan 加倍 → OOM
- 无独立的 SubagentStop 会计层 → 无法回答"当前还有多少 agent 在场上"

**关于 "subagent 劫持主 loop" 的澄清**：这曾是最初的假设，但查 Claude Code 官方文档后证实**不成立**——`Stop` 事件仅主会话触发，subagent 完成走独立的 `SubagentStop` 事件。hooks.json 里如果只注册 `Stop`，subagent 的生命周期结束对主会话 hook 不可见。**真正的病因是 agent 生命周期缺少会计层**，不是 hook 层劫持。v3.1 起注册 SubagentStop hook 作为 teardown accounting，配合 `/pua:team-status` 提供"当前在场阵容"。

本文定义缺失的 3 步，并给出可执行的命令/信号/检查清单。

---

## 生命周期 7 阶段对照

| # | 阶段 | 标准协议 | PUA v3 前 | PUA v3 后 |
|---|------|---------|----------|----------|
| 1 | Define | Task Prompt 六要素 | ✅ p9-protocol 阶段二 | 不变 |
| 2 | Spawn | Agent/TeamCreate | ✅ agent-team.md | 不变 |
| 3 | Monitor | 轮询 / SendMessage | ✅ p9-protocol 阶段三 | 不变 |
| 4 | Accept | P8/P9 验收 | ✅ p9-protocol 阶段四 | 不变 |
| **5** | **Release** | 显式释放信号 | ❌ 无 | 本文 §Release |
| **6** | **Cleanup** | 清 worktree / pane | ❌ 无 | 本文 §Cleanup |
| **7** | **Orphan handling** | 孤儿检测 + 回收 | ❌ 无 | 本文 §Orphan |

---

## §Release — 6 条释放规则

### R1. P9 验收通过必须发 `[TEARDOWN]` 信号

**WHY** ：验收通过 ≠ agent 释放。P9 默认会继续分配下一个任务给同一个 P8，但如果没有下一个任务，老 P8 就这样挂在那里。`[TEARDOWN]` 是明确的"下场"指令。

**HOW** ：P9 在验收旁白后，追加一行：

```
[TEARDOWN] p8-backend | reason: all_tasks_completed | release_resources: true
```

若还有下一轮任务：

```
[REASSIGN] p8-backend | next_task: <task_id> | keep_agent: true
```

二选一必须显式，不允许默认静默。

### R2. P10 换届强制 teardown 整个 P9 团队

**WHY**：P9 切换（/pua:p9 → 不同项目）时，旧 P9 管理的 P8 全部成了孤儿——没有老板会来验收它们的交付。

**HOW**：P10 下发换届指令时必须级联：

```
[TEARDOWN-CASCADE] p9-current | descendants: [p8-backend, p8-frontend, p7-*] | reason: p9_rotation
```

### R3. worktree agent 完成后自动回收 worktree

**WHY**：`isolation: "worktree"` 创建的 git worktree 不会自动删除。10 个 worktree 就是 10 份代码副本，磁盘和 context 双重浪费。

**HOW**：P8/P9 收到 `[P7-COMPLETION]` 后，执行：

```bash
# 从 Agent result 拿 worktree 路径和 branch
git worktree remove <worktree_path> --force
git branch -D <worktree_branch>  # 如果已合并
```

### R4. TeamCreate 必须配对 TeamDelete

**WHY**：tmux pane 不会因为 agent 完成而自动关闭。team_name 会一直占用 session 标识符。

**HOW**：P9 在所有 P8 发完 `[P8-COMPLETION]` 后，收尾指令：

```
TeamDelete({team_name: "<project-team>"})
```

若跨 sprint 需要保留团队，显式声明：

```
[TEAM-HIBERNATE] <team_name> | reason: next_sprint_continues | ttl: 24h
```

### R5. background agent 默认 TTL = 30min

**WHY**：`run_in_background: true` 启动的 agent 不会被自动 kill。忘了回收 = 永久后台进程吃 token。

**HOW**：spawn 时记录 spawn_time 到 state；超过 30min 未返回 → 主线程主动 `TaskStop`：

```bash
# 在 state 文件里记 agent_id 和 spawn_time
# 巡检命令（也可用作 /pua:reap-orphans 后端）
jq '.agents[] | select(.spawn_time < (now - 1800)) | .id' ~/.claude/pua/active-agents.json
```

### R6. subagent 禁止再 spawn team（禁嵌套孤儿）

**WHY**：subagent 自己创建 team 后，主会话完全看不见这些 agent。一旦 subagent 退出，这个 team 就彻底失联。

**HOW**：P8 被 P9 spawn 后，**只能**用 `Agent tool` spawn P7，**不能**用 `TeamCreate`。P9 级别才允许建 team。检测命令：

```
hook 层读 HOOK_INPUT.parent_session_id，若非空且尝试 TeamCreate → 拒绝
```

---

## §Cleanup — 主动清理 checklist

每次 `[TEARDOWN]` 触发后执行：

```bash
# 1. 清 worktree（若有）
git worktree list --porcelain | grep -A1 "<branch>" && git worktree remove ...

# 2. 清 state file
rm -f "$HOME/.claude/pua/agent-<id>.state"

# 3. 关 tmux pane（若是 TeamCreate 成员）
tmux kill-pane -t <pane_id>

# 4. 记录到 teardown log
echo "{\"agent\":\"<id>\",\"reason\":\"<reason>\",\"ts\":\"$(date -u +%FT%TZ)\"}" >> "$HOME/.claude/pua/teardown.jsonl"
```

---

## §Orphan — 孤儿检测与回收

**什么是孤儿**：
- state 文件 mtime > 30 分钟
- 无对应活跃 session
- 无心跳更新

**三层防御**：

1. **Stop hook 层**（自动）：每次主会话 Stop 时扫一次 `$HOME/.claude/pua/loop-*.md`，stale 的直接清理（已在 `pua-loop-hook.sh` 实现）
2. **SessionStart hook 层**（自动）：新会话启动时扫 state 目录，stale 的提示用户确认
3. **用户显式**（手动）：`/pua:reap-orphans` 一键扫描 + 回收

---

## §Switches — 开关语义映射

PUA 的 14 个 slash 命令在本协议下的生命周期语义：

| 命令 | 原语义 | 扩展后语义 | 映射操作 |
|------|--------|-----------|---------|
| `/pua:on` | 打开默认加载 | 不变 | config: always_on=true |
| `/pua:off` | 关闭默认加载 | **+ 停 loop + 级联 teardown** | off → cancel-loop → teardown-all |
| `/pua:cancel-pua-loop` | 删 state file | **+ 原子级联清理** | rm state + cleanup worktree + kill pane |
| `/pua:team-status` 🆕 | — | 列活跃 agent / PID / TTL | 读 state 目录 + jq 汇总 |
| `/pua:reap-orphans` 🆕 | — | 扫 stale agent 并 TaskStop | age > 30min 批量回收 |
| `/pua:teardown-all` 🆕 | — | 级联释放 P10→P9→P8→P7 | 发 TEARDOWN-CASCADE 到所有层 |

**设计原则**：
- **幂等**：重复执行同一开关不会产生副作用（re-rm 无害、re-kill 先检查）
- **级联**：顶层开关触发底层清理，反向不允许（P7 不能 teardown P8）
- **可观测**：所有 teardown 写 `$HOME/.claude/pua/teardown.jsonl`，便于复盘

---

## §自治 — 插件自动启动场景

因为 PUA 是 `default=true` 自动加载的，不能假设用户会主动清理。所以关键是让 hook 长出 GC 能力：

| Hook 事件 | 自治行为 | 实际落地 |
|----------|---------|---------|
| `SessionStart` | 扫 stale loop state，提示用户确认回收 | ✅ `session-restore.sh` |
| `PreCompact` | dump 活跃 agent 清单到 HANDOFF | ✅ inline prompt hook |
| `Stop`（主会话） | 走 loop 逻辑 + stale 兜底清理 | ✅ `pua-loop-hook.sh` + Gate 0 防御 |
| `SubagentStop` | **agent 完成会计**：写 teardown.jsonl + 从 active-agents.json 移除 | ✅ `subagent-teardown.sh`（v3.1 新增） |
| `PostToolUse:Task`（计划） | spawn 时记录 agent_id 到 active-agents.json | ⏳ 待实现（需 Claude Code 该事件支持） |

**重要**：Claude Code 中 Stop 事件**仅**主会话触发，subagent 的 Stop 事件不会传到 Stop 钩子——所以监控 subagent 必须用独立的 SubagentStop 注册。pua-loop-hook.sh 的 Gate 0 保留作为"防御层"兜住未来调度变化，但不是必需防线。

---

## 验收

本协议落地的判定标准：

- ✅ `TeardownDelete` 在 skill 文档里出现次数 ≥ `TeamCreate` 的一半
- ✅ `teardown` / `释放` / `回收` 在 p9-protocol 阶段四后出现 ≥ 3 次
- ✅ `pua-loop-hook.sh` 有 Gate 0（subagent 识别）
- ✅ `/pua:team-status`、`/pua:reap-orphans`、`/pua:teardown-all` 存在
- ✅ `$HOME/.claude/pua/teardown.jsonl` 可写且有 schema
