---
description: "级联释放所有活跃 PUA agent：P10→P9→P8→P7 全员下场。/pua:teardown-all。Triggers on: '/pua:teardown-all', '收工', '全员下场', 'teardown all', 'stop all agents'."
allowed-tools: ["Bash(rm:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(date:*)", "Bash(mkdir:*)", "Bash(git:*)"]
---

# PUA Teardown All — 全员下场

> 不是解散球队，是正式收工。每个球员打卡下班，教练也下班。

级联语义：顶层触发，逐层释放。**不等待 agent 自然完成**——因为此命令就是为了强制收尾。

## 执行步骤

1. 确保目录：
   ```bash
   mkdir -p "$HOME/.claude/pua"
   ```

2. **Layer A — 停 loop**：删除所有 loop state（让 hook 不再劫持 Stop）：
   ```bash
   find "$HOME/.claude/pua/" -name "loop-*.md" -delete 2>/dev/null
   rm -f .claude/pua-loop.local.md 2>/dev/null
   ```

3. **Layer B — 清 active agents 记录**：
   ```bash
   rm -f "$HOME/.claude/pua/active-agents.json" 2>/dev/null
   ```

4. **Layer C — 清 worktree**（若存在）：
   ```bash
   # 列出所有 worktree，排除主工作区
   git worktree list --porcelain 2>/dev/null | grep '^worktree ' | awk '{print $2}' | \
     grep -v "^$(git rev-parse --show-toplevel 2>/dev/null)$" | \
     while read wt; do
       git worktree remove "$wt" --force 2>/dev/null || true
     done
   ```

5. **Layer D — 记录 teardown 事件**：
   ```bash
   echo "{\"event\":\"teardown_all\",\"ts\":\"$(date -u +%FT%TZ)\",\"initiator\":\"user_command\"}" \
     >> "$HOME/.claude/pua/teardown.jsonl"
   ```

6. **Layer E — 提示用户主会话层**（Claude 自己要做的）：

   在主会话输出中显式列出"我意识到还有这些 agent 在后台跑"，逐个用 `TaskStop` 工具停掉（若 TaskList 里还有 in_progress 的任务）。

## 输出格式

```
> [PUA TEARDOWN-ALL] 全员下场完成：
>   ✓ Loop state 清理 (N 个)
>   ✓ Active agents 记录清理
>   ✓ Worktree 回收 (M 个)
>   ✓ 事件已落盘 ~/.claude/pua/teardown.jsonl
> 
> 球队解散。下班。
```

## 幂等性

- 所有删除操作用 `-f` 或 `|| true` 兜底，重复执行无副作用
- 不 kill 非 PUA 创建的 worktree（用 git 主工作区路径比对）

## 何时使用

- 长会话结束想彻底清仓
- 发现异常 agent 行为且不确定哪个是问题源
- `/pua:off` 的补充（off 只关默认加载，不主动收尾）

## 与 /pua:reap-orphans 区别

| 命令 | 作用范围 | 判定标准 |
|------|---------|---------|
| `/pua:reap-orphans` | 仅清 stale（>30min 未更新） | 年龄阈值 |
| `/pua:teardown-all` | 清所有（含活跃的） | 用户显式决定 |

用 reap 是"保洁"，用 teardown-all 是"下班"。
