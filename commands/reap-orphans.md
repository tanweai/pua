---
description: "扫描并回收所有孤儿 PUA agent/state。/pua:reap-orphans。Triggers on: '/pua:reap-orphans', '清理孤儿 agent', 'reap orphan', 'cleanup stale agents'."
allowed-tools: ["Bash(find:*)", "Bash(stat:*)", "Bash(rm:*)", "Bash(ls:*)", "Bash(date:*)", "Bash(mkdir:*)"]
---

# PUA Reap Orphans — 孤儿回收

Keeper Test 的工程版：打完就下场，拖着不走的一律清理。

## 执行步骤

1. 确保目录存在：
   ```bash
   mkdir -p "$HOME/.claude/pua"
   ```

2. 扫描 30 分钟未更新的 loop state（orphan 判定线）：
   ```bash
   find "$HOME/.claude/pua/" -name "loop-*.md" -type f -mmin +30 2>/dev/null
   ```

3. 同步扫 legacy 相对路径：
   ```bash
   find .claude/ -maxdepth 1 -name "pua-loop.local.md" -type f -mmin +30 2>/dev/null
   ```

4. 对每个匹配文件：
   - 读 session_id 和 iteration（若可解析）
   - 记录到 `$HOME/.claude/pua/teardown.jsonl`：
     ```bash
     echo "{\"reaped\":\"<file>\",\"age_min\":<N>,\"ts\":\"$(date -u +%FT%TZ)\",\"reason\":\"orphan_reap\"}" \
       >> "$HOME/.claude/pua/teardown.jsonl"
     ```
   - 删除 state 文件：
     ```bash
     rm -f "<file>"
     ```

5. 若存在 `active-agents.json`，清理 spawn_time > 30min 的记录（需 jq）：
   ```bash
   test -f "$HOME/.claude/pua/active-agents.json" && \
     jq '.agents |= map(select(.spawn_time > (now - 1800)))' \
       "$HOME/.claude/pua/active-agents.json" > "$HOME/.claude/pua/active-agents.json.tmp" && \
     mv "$HOME/.claude/pua/active-agents.json.tmp" "$HOME/.claude/pua/active-agents.json"
   ```

6. 输出结果：

   ```
   > [PUA REAP] 清理了 N 个孤儿状态：
   >   - loop-abc123.md (age 1h42m)
   >   - .claude/pua-loop.local.md (age 3h05m)
   > 全部已落盘到 ~/.claude/pua/teardown.jsonl 备查。
   ```

7. 若无孤儿：

   > [PUA REAP] 没发现孤儿。球队纪律良好。

## 幂等性

- 重复执行无害：`rm -f` 对不存在文件不报错
- teardown.jsonl 追加而非覆盖，保留完整历史

## 安全保护

- 仅清理 `$HOME/.claude/pua/` 和 `.claude/pua-loop.local.md`，不越权
- 年龄阈值硬编码 30min，不接受用户参数（防误杀活跃 loop）
