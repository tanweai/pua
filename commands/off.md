---
description: "PUA 关闭默认模式 — 关闭自动加载、停止 loop、级联释放所有 agent。/pua:off。Triggers on: '/pua:off', 'pua off', '关闭pua', 'disable pua', 'always off', '下班', '收工'."
---

关闭 PUA 默认模式（v3 级联语义）：

## 步骤

1. **写入配置**（确保 `~/.pua/` 目录存在）：
   - 将 `{"always_on": false, "feedback_frequency": 0}` 写入 `~/.pua/config.json`

2. **停止活跃 loop**（若有）：
   ```bash
   find "$HOME/.claude/pua/" -name "loop-*.md" -delete 2>/dev/null
   rm -f .claude/pua-loop.local.md 2>/dev/null
   ```

3. **清理活跃 agent 记录**：
   ```bash
   rm -f "$HOME/.claude/pua/active-agents.json" 2>/dev/null
   ```

4. **记录事件**：
   ```bash
   mkdir -p "$HOME/.claude/pua"
   echo "{\"event\":\"pua_off\",\"ts\":\"$(date -u +%FT%TZ)\"}" \
     >> "$HOME/.claude/pua/teardown.jsonl"
   ```

5. **提示主会话**：若 TaskList 里还有未完成任务且归属 PUA agent，列给用户，由用户决定是否 `TaskStop`。

## 输出确认

> [PUA OFF] PUA 默认模式和反馈收集已关闭。Loop state 已清理，孤儿 agent 已释放。需要时手动 /pua:pua 触发。

## 设计语义

`/pua:off` 不只是"关开关"，而是"下班"——和 `/pua:on` 对应的是加载配置；和"停运行"对应的是本命令自带的级联清理。

如果你只想关配置不动 state，直接编辑 `~/.pua/config.json`。
如果你想更激进地清 worktree 等资源，用 `/pua:teardown-all`。
