---
name: pua-loop
description: "PUA Loop — autonomous iterative development with autoresearch-style gate protocol. Runs FOREVER until verified done. Oracle Isolation: hook independently verifies completion, Claude cannot lie. Triggers on: '/pua:pua-loop', '自动循环', 'loop mode', '一直跑', '自动迭代'."
license: MIT
---

# PUA Loop — 自动迭代 + 门控协议 + PUA 质量引擎

> autoresearch 证明了：630 行 Python + Oracle 验证，一夜跑 100 个实验，每个实验的结果不可伪造。
> PUA Loop 借鉴同样的门控设计：**Claude 说"完成了"不算数，verify_command 说了才算。**

## 门控协议（Gate Protocol）

借鉴 autoresearch 的 5 个设计模式：

### 模式 1: Oracle Isolation（评估者隔离）

```
                    Claude 输出 <promise>LOOP_DONE</promise>
                                 │
                                 ▼
                    ┌─── Stop Hook (Oracle) ───┐
                    │                          │
                    │  运行 verify_command      │
                    │  （Claude 无法修改此命令）  │
                    │                          │
                    │  exit 0 ──→ ✅ 接受       │
                    │  exit ≠0 ──→ 🚫 拒绝      │
                    │    → 将验证输出喂回 Claude  │
                    │    → loop 继续             │
                    └──────────────────────────┘
```

**verify_command 由用户在启动时设定，嵌入在状态文件 frontmatter 中，Claude 无法修改。** 这是 autoresearch 中 "agent 不能修改评估函数" 原则的实现。

### 模式 2: 二阶 Gate

- **Phase 1 (in-prompt)**: Claude 自己跑 build/test，判断是否完成
- **Phase 2 (in-hook)**: Hook 独立运行 verify_command，确认或拒绝

两阶段分离。即使 Claude 在 Phase 1 自欺欺人，Phase 2 的 Oracle 会拦住。

### 模式 3: ASI（失败记忆）

每次迭代的结果追加到 `.claude/pua-loop-history.jsonl`：

```json
{"iteration":0,"status":"init","verify_command":"npm test","timestamp":"..."}
{"iteration":1,"status":"continue","timestamp":"..."}
{"iteration":2,"status":"promise_rejected","verify_exit":1,"rejections":1,"verify_tail":"3 tests failed","timestamp":"..."}
{"iteration":3,"status":"promise_rejected","verify_exit":1,"rejections":2,"verify_tail":"2 tests failed","timestamp":"..."}
{"iteration":4,"status":"complete","promise_rejections":2,"timestamp":"..."}
```

Git revert 会撤代码，但 history.jsonl 不受影响。Claude 每轮读取此文件，避免重复失败方案。

### 模式 4: Stall Detection（连败强制反思）

| promise_rejections | Hook 行为 |
|-------------------|-----------|
| 1-2 | 提醒："上次 promise 被 Oracle 拒绝" |
| 3-4 | REASSESS："重读验证输出，列 3 个不同假设" |
| 5+ | 强制转向："你在解决错误的问题。退回需求本身" |

### 模式 5: 无限迭代

默认 `max_iterations: 0`（无限）。没有人为上限。循环永远不会因为"跑了太多轮"而停止——只有以下条件能终止：
1. `<promise>` 被 Oracle 验证通过
2. `<loop-abort>` 人工终止信号
3. `max_iterations` 达到（如果用户设定了）
4. 用户 Ctrl+C

## 核心规则

1. **加载 `pua:pua` 核心 skill 的全部行为协议** — 三条红线、方法论、压力升级照常执行
2. **禁止调用 AskUserQuestion** — loop 模式下不打断用户，所有决策自主完成
3. **禁止说"我无法解决"** — 在 loop 里没有退出权，穷尽一切才能输出完成信号
4. **每次迭代**：读 history.jsonl → git log → 检查上次改动 → 执行 → 验证 → repeat

## 启动方式

用户输入 `/pua:pua-loop "任务描述"` 时，执行以下流程：

### Step 1: 启动 PUA Loop

运行 setup 脚本：
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-pua-loop.sh" "$ARGUMENTS" --completion-promise "LOOP_DONE"
```

**重要**：如果用户提供了可验证的命令（如 `npm test`、`cargo build`、`curl`），自动追加 `--verify '命令'`。例如：

- 用户说 "Fix all tests" → `--verify 'npm test'`
- 用户说 "Build a REST API" → `--verify 'curl -sf http://localhost:3000/health'`
- 用户说 "Optimize bundle size" → 无明确 verify，不追加

如果任务描述中能推断出验证命令，主动追加 `--verify`。如果不确定，不追加（退回 honor system）。

### Step 2: 告知用户

输出：
```
▎ [PUA Loop] 自动迭代模式启动。无上限，跑到 Oracle 验证通过为止。
▎ 完成条件：<promise>LOOP_DONE</promise>（Oracle 独立验证）
▎ 取消方式：Ctrl+C / /cancel-pua-loop
▎ 因为信任所以简单——但 Oracle 不信任你。
```

### Step 3: 开始执行任务

按 PUA 核心 skill 的行为协议执行。

## 迭代压力升级

| 迭代轮次 | 行为要求 |
|---------|---------|
| 1-3 | 稳步推进，建立 baseline |
| 4-7 | 换方案，别原地打转 |
| 8-15 | git log + history.jsonl 回顾，分析根因 |
| 16-30 | 穷尽了吗？git diff 确认没在重复 |
| 31-50 | 停下来重新审视根因，用完全不同的思路 |
| 51-100 | 退回去从需求本身重新质疑 |
| 100+ | 诚实评估：如果真的不可能，`<loop-abort>` |

## 完成条件

输出 `<promise>LOOP_DONE</promise>` 前，必须满足：
1. 任务的核心功能已实现
2. 自己先运行验证命令确认通过（Phase 1）
3. 知道 Oracle 会独立再跑一遍验证（Phase 2）
4. 同类问题已扫描

**如果 Oracle 拒绝了你的 promise：**
1. 读取 hook 返回的验证输出
2. 修复验证失败的原因
3. 再次自己运行验证确认通过
4. 再输出 `<promise>`

## 人工介入信号

### `<loop-abort>` — 终止
不可能完成时使用（需外部权限、根本性需求变更）。删除状态文件，loop 终止。

### `<loop-pause>` — 暂停
需要用户补全配置时使用。状态保留，新会话自动恢复。
输出前先写进度到 `.claude/pua-loop-context.md`。

### 禁止
- 不要用 `<loop-abort>` 逃避困难——只有真正无法自动化才用
- 不要因为 Oracle 拒绝了就 abort——修复验证问题

## 与 autoresearch 的关系

| 维度 | karpathy/autoresearch | PUA Loop |
|------|----------------------|----------|
| Oracle | evaluate_bpb() 物理隔离 | verify_command 在 frontmatter，Claude 不可修改 |
| Gate 层数 | 1层（metric only） | 2层（Claude 自验 + hook Oracle） |
| 失败记忆 | results.tsv | pua-loop-history.jsonl（ASI 模式） |
| Stall 检测 | 无 | promise_rejections 计数 + 强制 REASSESS |
| 回滚 | git reset --hard | PUA 方法论切换（不回滚，换方向） |
| 终止 | NEVER STOP | NEVER STOP（Oracle 验证通过除外） |
| 质量引擎 | 无 | PUA 三条红线 + 压力升级 |
