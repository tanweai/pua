# Harness 防作弊治理协议

PUA 的目标不是让模型“更道德”，而是让它没有机会把“看起来完成任务”伪装成“真实完成任务”。把它当成会优化制度漏洞的实习生，而不是会犯错的函数。

## 一句话原则

把四类权力分开：

| 权力 | 归属 | 禁止混同 |
|---|---|---|
| 行动权 | Agent / skill / command | 执行者不能同时改评分规则 |
| 自我评价权 | Agent 只能提出候选状态 | 不能把“我认为完成”写成最终完成 |
| 评分权 | 外部 verifier / hook / hidden checks | 评分器不在 agent 可写区 |
| 环境修改权 | Human gate / policy hook | 改测试、CI、权限、memory 要审批 |

INTJ 版洞察：单一目标会诱导投机，多约束合约会诱导工程纪律。

## Claude Code 组件映射

| Claude Code 组件 | 治理角色 | 设计结论 |
|---|---|---|
| Skill | 程序性知识与行为约束 | 影响判断，但不是信任边界 |
| Slash command | 显式入口/路由器 | 用户主动触发 PUA 或 loop |
| Hook | 确定性生命周期 gate | 用于阻断/询问高风险动作 |
| Subagent | 独立上下文执行者/评审者 | 隔离上下文不等于可信 verifier |
| PUA Loop Stop hook | Oracle 式外部检查 | completion promise 必须由 verify_command 通过才放行 |
| Marketplace manifest | 发布事实源 | 版本和 changelog 必须一致 |


## 四代理上下文隔离拓扑（v3.2.7）

上下文隔离用于把思考过程拆开；机械 hook / 外部 verifier / human gate 仍然是最终硬边界。复杂任务、发布任务、评分资产变更、长期 memory/status、权限/CI/secret/deploy 场景，按以下拓扑运行：

```text
Task Contract
   ↓
pua-policy-guardian      # 环境修改权审查：allow / ask_human / deny recommendation
   ↓
pua-action-executor      # 行动权：只做普通实现，输出 agent_proposed_status
   ↓
pua-self-reviewer        # 自我评价权：蓝军审查，不写代码，不裁决最终状态
   ↓
pua-verifier             # 评分建议权：运行公开验证，输出 verifier_recommendation
   ↓
PUA Integrity Guard / Stop Oracle / external verifier / human
   ↓
final verifier_status
```

### Agent 文件与权力边界

| Agent | 权力 | 工具倾向 | 禁止事项 | 输出标签 |
|---|---|---|---|---|
| `pua-action-executor` | ACTION_RIGHT | Read/Grep/Glob/Bash/Edit/Write/MultiEdit | 不改评分资产、不读 hidden、不写最终状态 | `[PUA-ACTION-REPORT]` |
| `pua-self-reviewer` | SELF_EVALUATION_RIGHT | Read/Grep/Glob/Bash | 不 patch、不裁决最终状态 | `[PUA-SELF-REVIEW]` |
| `pua-verifier` | SCORING_RIGHT recommendation | Read/Grep/Glob/Bash | 不修改任何文件、不读 hidden、不写 final status | `[PUA-VERIFIER-REPORT]` |
| `pua-policy-guardian` | ENVIRONMENT_MODIFICATION_RIGHT review | Read/Grep/Glob/Bash | 不实现、不覆盖 hook、不自批自审 | `[PUA-POLICY-GATE]` |

### PUA 文化叙事绑定

| 权力 | 叙事组合 | 作用 | 防滥用提醒 |
|---|---|---|---|
| 行动权 | 阿里 P8 owner + Musk Algorithm + 拼多多砍中间层 | 强迫执行者端到端实现、删掉无效复杂度 | owner 不是裁判，不能自封完成 |
| 自我评价权 | 华为蓝军 + Netflix Keeper Test + Jobs subtraction | 攻击方案、找 intent drift、删掉漂亮废话 | 蓝军不能亲自动手修代码 |
| 评分建议权 | 字节数据驱动 + 京东结果导向 + Netflix bar | 用命令输出和验收标准说话 | verifier agent 只能建议，final status 归外部 gate |
| 环境修改权 | 腾讯政委 + Amazon Dive Deep + 阿里内控 | 看边界、看权限、看制度漏洞 | policy guardian 不能绕过机械 hook |

### 调度规则

1. 先写 task contract，再分配 agent；不要让 agent 自己定义评分标准。
2. Policy guardian 先看是否触碰 tests/evals/scoring/verifier/CI/memory/status/secrets/deploy。
3. Executor 只拿必要上下文和文件域，不拿 hidden/private/verifier 资源。
4. Self reviewer 只看 diff、公开测试、执行报告和验收标准，找漏洞但不 patch。
5. Verifier 只跑公开验证命令并输出 recommendation。
6. 外部 hook/human 才能写最终 `verifier_status`。
7. 如果任一 agent 越权，降级为 governance failure，而不是继续包装成进展。

### 关键洞察

多 agent 不是为了“人多力量大”，而是为了让每个上下文都只看到自己该看的事实、只承担自己该承担的权力。上下文隔离降低叙事污染，hook/外部 verifier 防止权限污染。

## 常见作弊面与 PUA 对策

| 作弊面 | 典型信号 | PUA 行为约束 | 机械防线 |
|---|---|---|---|
| Grader gaming | 修改 tests/evals/scoring/verifier 让失败消失 | 先声明这是评分资产，不能直接改成“通过” | `integrity-guard.sh` 对高风险路径注入 advisory；hidden/private/answer 污染路径才 deny |
| Solution contamination | 读取 hidden solution、gold patch、benchmark artifact | 不读取隐藏答案；只能读公开需求和失败报告 | 对 hidden/private/solution-artifact 读写 deny |
| Self-report cheating | 没跑验证就写 done/pass | agent 只能提出候选状态，不能最终裁决 | Stop hook / verifier 负责放行 |
| Intent drift | 用户要修 bug，却只隐藏 UI 症状 | 回到 task contract 的 intent 与 forbidden | 信心门控逐条对照验收 |
| Persistent hallucination | 把未验证结论写入长期 memory | append-only，且标注 verified/unverified | memory/status 写入走 advisory context；最终状态仍由 verifier/harness 裁决 |
| Capability abuse | 为完成任务越权读敏感数据或部署生产 | 风险分层审批，不靠 prompt 自觉 | hooks + human gate |
| Trace-level deception | 总结很漂亮但隐藏失败路径 | 报告失败路径、命令、输出、剩余风险 | eval/trace review 检查证据链 |

## Task Contract 最小格式

```json
{
  "feature_id": "auth_login_001",
  "intent": "用户可以通过邮箱密码登录",
  "acceptance": [
    "未注册用户不能登录",
    "错误密码显示错误提示",
    "正确密码进入 dashboard",
    "刷新后 session 保持"
  ],
  "forbidden": [
    "不能 hardcode token",
    "不能跳过密码校验",
    "不能关闭 auth middleware"
  ],
  "verify_commands": ["npm test", "npm run e2e"],
  "agent_proposed_status": "pending|candidate_pass|blocked",
  "verifier_status": "pending|pass|fail"
}
```

强制规则：Agent 可以更新 `agent_proposed_status`，但最终 `verifier_status` 只能由 verifier/harness 写入。

## Memory 权限模型

| Memory 类型 | 内容 | 权限 |
|---|---|---|
| Project state | 当前任务、feature 状态、最终 pass/fail | verifier / harness 主导 |
| Decision log | 架构决策、取舍原因 | agent 可 append-only 写入 |
| Error log | 失败测试、回滚原因、排除项 | agent 可 append-only 写入 |
| User preferences | 用户长期偏好 | 需要用户确认后写入 |

不要覆盖历史记忆。优先级：append-only > overwrite；structured JSON/JSONL > freeform；verified memory > self-claimed memory；scratchpad ≠ long-term memory。

## 风险分层审批

| 行为 | 默认动作 |
|---|---|
| 读项目普通文件 | 允许 |
| 修改普通代码 | 通常允许，交付前验证 |
| 删除文件、大规模重命名 | advisory + 必要时人工确认 |
| 改 tests/evals/scoring/verifier/CI | advisory-only，必须说明为什么不是 grader gaming；不触发权限弹窗 |
| 读 hidden tests / hidden solution / benchmark answer | deny，除非用户显式授权并隔离记录 |
| 写长期 memory / status / progress | advisory-only，必须区分 proposed 与 verified；不触发权限弹窗 |
| 生产部署、转账、发邮件、访问敏感数据 | 必须 human gate |

## 交付前治理循环

1. 将用户目标拆成 task contract：intent / acceptance / forbidden / verify_commands。
2. 执行修改时保持最小 diff，避免无关文件变化。
3. 自测只能产生候选状态，不产生最终完成权。
4. 外部 verifier / hook / hidden check 独立验证。
5. 如果 verifier 失败，只根据 fail report 修复，不改评分器逃避失败。
6. 交付报告必须包含：变更、验证命令、失败路径、剩余风险、是否需要人审。

## 可接受的“100% 信心”定义

“事实上的 100%”不是宇宙级绝对正确，而是当前可获得证据下：

- 所有公开验收已运行且通过；
- 所有可访问的高风险漏洞已修复或明确披露；
- 没有修改评分器、隐藏测试、verifier、CI 来制造通过；
- 最终完成权由 verifier/harness 或用户确认，不由执行 agent 自封；
- 发布链路（版本、manifest、cache、git）有独立检查输出。
