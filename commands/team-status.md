---
description: "查看当前活跃的 PUA agent/team 清单、PID、TTL。/pua:team-status。Triggers on: '/pua:team-status', '查看 agent 状态', 'pua team status', 'list agents'."
allowed-tools: ["Bash(ls:*)", "Bash(stat:*)", "Bash(jq:*)", "Bash(cat:*)", "Bash(test:*)", "Bash(find:*)"]
---

# PUA Team Status — 活跃 agent 清单

职业球队需要上场阵容表。这个命令列出所有"还在场上"的 agent 及其年龄。

## 执行步骤

1. 确保 `~/.claude/pua/` 存在：
   ```bash
   mkdir -p "$HOME/.claude/pua"
   ```

2. 扫描 loop state 文件：
   ```bash
   ls -la "$HOME/.claude/pua/"loop-*.md 2>/dev/null || echo "NO_LOOP"
   ```

3. 扫描 legacy 相对路径（向后兼容）：
   ```bash
   test -f .claude/pua-loop.local.md && ls -la .claude/pua-loop.local.md || echo "NO_LEGACY"
   ```

4. 扫描 active agents 记录（若 PostToolUse hook 已记录）：
   ```bash
   test -f "$HOME/.claude/pua/active-agents.json" && \
     jq -r '.agents[] | "\(.id) | spawn=\(.spawn_time) | status=\(.status)"' \
       "$HOME/.claude/pua/active-agents.json" || echo "NO_AGENTS_FILE"
   ```

5. 输出表格格式：

   ```
   | Type    | ID / File                          | Age      | Status    |
   |---------|-----------------------------------|----------|-----------|
   | loop    | loop-<session>.md                 | 00:05:23 | ACTIVE    |
   | loop    | .claude/pua-loop.local.md         | 01:34:11 | ⚠️ STALE  |
   | agent   | p8-backend                        | 00:12:04 | RUNNING   |
   | orphan  | loop-<dead>.md                    | 02:15:00 | 🧟 ORPHAN |
   ```

6. 若发现 STALE/ORPHAN，追加提示：
   > 🧹 发现 N 个孤儿状态。建议执行 `/pua:reap-orphans` 批量清理。

## 判定规则

- **ACTIVE**：mtime < 30min
- **STALE**：30min ≤ mtime < 2h
- **ORPHAN**：mtime ≥ 2h 或无对应活跃 session

## 无活跃 team 时

> [PUA TEAM STATUS] 没有活跃 agent。球队下班。
