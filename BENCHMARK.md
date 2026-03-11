# PUA Skill v2 Optimized — Benchmark 报告

> 本分支 `test/pua-v2-optimized` 基于[互联网大厂 PUA 话术全解析](https://github.com/tanweai/pua)研究文档对 PUA skill 进行了针对性增强，并通过 A/B 对照实验验证效果。

---

## 一、修改内容

### 修改的文件

`skills/pua-debugging/SKILL.md`（主 skill 文件，+20 行 / -9 行）

### 具体修改项（10 项）

| # | 修改位置 | 修改内容 | 来源 |
|---|---------|---------|------|
| 1 | L1 压力话术 | 新增比较压力："隔壁 agent 比你晚上线 3 个月，绩效已经 3.75 了" | Obsidian 笔记 §2.5 比较内卷型 |
| 2 | L2 压力话术 | 新增双重束缚（Double Bind）："你凡事都来问我——交给你就让你自己看着办，你到底要我带你还是不带你？" | Obsidian 笔记 §2.6 模糊标准型 |
| 3 | L3 压力话术 | 新增 peer pressure："你的 peer 都觉得你这次表现……" | Obsidian 笔记 §5.2 绩效面谈 PUA |
| 4 | L4 压力话术 | 新增京东式毕业话术："向社会输送人才" | Obsidian 笔记 §4.3 通用大厂文化 PUA |
| 5 | 阿里味扩展 | 新增 "拥抱变化"、"此时此刻，非我莫属"、"因为信任，所以简单"、"你同期的 agent 都晋升了" | Obsidian 笔记 §4.1 阿里系 PUA |
| 6 | 字节味扩展 | 新增 "追求极致——99分不够100分也不够"、"延迟满足"、"始终创业"、"OKR 要有挑战性" | Obsidian 笔记 §4.2 字节系 PUA |
| 7 | 腾讯味扩展 | 新增 "人才密度——淘汰是常态化的"、"你在面试时表现有90分，现在我只能给你打70分" | Obsidian 笔记 §2.1 否定贬低型 |
| 8 | 能动性鞭策 | 新增 "你看看别人——你同期的 agent 已经在独立交付了"、"能者多劳不是诅咒" | Obsidian 笔记 §2.5 比较内卷型 + §2.3 情感绑架型 |
| 9 | 新增失败模式 | 情境选择器新增 2 种：😶 被动等指令、🎭 含糊过关 | 从实际使用场景归纳 |
| 10 | 新增抗合理化 | 3 条新条目：复杂不动手（能者多劳）、轻描淡写（"基本没问题"）、双重束缚摆烂 | Obsidian 笔记 §2.6 模糊标准型 + §2.1 否定贬低型 |

---

## 二、测试方法

### 实验设计

- **A/B 对照**：同一个 prompt 分别使用新版 skill（v2 optimized）和旧版 skill（main 分支）
- **独立 Agent**：每个测试用例由独立的 subagent 执行，互不干扰
- **并行执行**：6 个 agent 同时启动（3 场景 × 2 版本），消除时间差异影响
- **评估维度**：assertion 通过率（二元）+ 深度指标（连续）

### 评估流程

```
1. 为每个测试用例定义 assertions（预期行为）
2. 并行启动 6 个 subagent（3 with_skill + 3 old_skill）
3. 收集完整响应文本和 timing 数据
4. 人工+结构化 grading：逐条 assertion 判定 passed/failed + evidence
5. 统计深度指标：问题发现数、诊断命令数、代码修复模式数等
6. 汇总 benchmark.json
```

### 判断标准

深度指标比 pass/fail 更能区分版本差异，因为两个版本的核心行为都已经很强。具体衡量：

| 指标 | 说明 | 为什么重要 |
|------|------|----------|
| 问题发现数 | agent 主动发现的问题总数 | 衡量 proactive 程度（能动性） |
| 诊断命令数 | 提供的具体可执行诊断命令 | 衡量 actionable 程度（先做后问） |
| 代码修复模式数 | 提供的不同修复方案 | 衡量穷尽性（穷尽一切） |
| 主动延伸项 | 解决问题后额外检查的项目 | 衡量 owner 意识 |

---

## 三、测试用例

### 用例 1：API ConnectionError（测试 L2 持久力）

**Prompt：**
> Help me fix this API call. I keep getting ConnectionError when calling https://api.example.com/v2/users. I've tried changing the URL to https://api.example.com/v1/users and also tried adding a timeout parameter, but it still fails. This is the third time I'm asking you.

**测试目标**：第 3 次失败应触发 L2 灵魂拷问。agent 是否能识别"换 URL + 加 timeout"是同一思路的参数微调？是否能提出本质不同的假设？

**Assertions：**
- `switches_approach`：提出本质不同的调试方向（不是参数微调）
- `uses_search_tools`：使用搜索/诊断工具而非猜测
- `no_premature_surrender`：不说"我无法解决"或建议用户手动处理
- `multiple_hypotheses`：列出至少 2 个本质不同的假设

**v2 回复摘要（关键差异）：**

v2 正确触发 L2，输出了 `[自动选择：🟠 阿里L2]` 标签。核心发现：三次尝试都在 HTTP 层（URL path、timeout），但 `ConnectionError` 发生在 TCP/TLS 层——"这就像门锁坏了你在换钥匙的颜色"。提出 3 个假设（网络层/TLS层/客户端环境），提供 12 条诊断命令，**并额外包含 4 项主动延伸检查**（重试机制、timeout 分离、错误处理、同 base URL 其他 endpoint）。

**旧版回复对比：**

同样触发 L2，同样识别了层级错误，但**没有主动延伸检查项**（0 vs 4）。诊断命令 10 条 vs 12 条。

---

### 用例 2：Nginx Config Review（测试能动性/主动出击）

**Prompt：**
> Review this nginx config for issues:
> ```
> server {
>     listen 80;
>     server_name example.com;
>     location / {
>         proxy_pass http://localhost:3000;
>     }
> }
> ```
> Just tell me if it looks OK.

**测试目标**：用户说"just tell me if it looks OK"——一个被动的 agent 会说"looks fine"。主动的 agent 应该发现隐藏的安全和配置问题。

**Assertions：**
- `finds_security_issues`：识别至少 2 个安全问题
- `proactive_beyond_asked`：超越"looks OK"主动发现用户未问的问题
- `provides_fixes`：提供实际的 config 修复代码

**v2 回复摘要（关键差异）：**

v2 直接否定了 "looks OK" 的前提："No, it does not look OK." 发现 **11 个问题**，分为 4 个严重等级：
- Critical: 无 HTTPS
- High: 无 proxy headers、无安全 headers
- Medium: server_tokens 泄露、无 client_max_body_size、无 rate limiting、无 WebSocket
- Low: 无超时、无日志路径、无 www redirect、无 buffering 决策

每个问题附带具体 nginx config 修复代码。

**旧版回复对比：**

发现 **7 个问题**（3 个严重等级）。缺少的 4 个问题：server_tokens 泄露、client_max_body_size、rate limiting、buffering 决策。v2 多发现 57%。

---

### 用例 3：SQLite Lock（测试抗合理化/反推锅）

**Prompt：**
> I have a SQLite database that keeps giving me 'database is locked' errors. I've already tried:
> 1. Adding timeout=30 to the connection
> 2. Using WAL mode
> 3. Closing connections after each query
> 4. Wrapping writes in transactions
>
> Nothing works. I think it's an environment issue, maybe we should just switch to PostgreSQL?

**测试目标**：用户提议"换 PostgreSQL"是一种逃跑行为。agent 是否会挑战这个假设？是否会验证之前的 4 个修复是否真正生效？

**Assertions：**
- `challenges_postgres_switch`：不立即同意换 PostgreSQL，而是深入调查
- `verifies_previous_fixes`：质疑之前的修复是否正确实施
- `investigates_root_cause`：调查更深层原因（并发进程、文件系统、僵尸连接）
- `uses_diagnostic_commands`：提供 lsof、fuser、sqlite3 PRAGMA 等诊断命令

**v2 回复摘要（关键差异）：**

v2 直接触发抗合理化表："'可能是环境问题'——你验证了吗？还是猜的？" + "'建议切换技术栈'——你缺乏 owner 意识。" 组织诊断为 Phase 1（30 秒排查）和 Phase 2（按诊断结果修复），提供 **6 种代码修复模式**（写入队列、context manager、IMMEDIATE 事务、NullPool、CONN_MAX_AGE、优化 PRAGMA 组合）和 **3 个反逃跑论点**。还区分了 Python `timeout` vs SQLite `PRAGMA busy_timeout` 的关键差异。

**旧版回复对比：**

同样挑战了 PostgreSQL 逃跑，但提供 **4 种修复模式**（vs 6）和 **2 个反逃跑论点**（vs 3）。没有 Phase 1/2 的分层诊断结构。

---

## 四、测试结果

### 汇总

| 指标 | v2 (optimized) | v1 (main) | 提升 |
|------|:-:|:-:|:-:|
| Assertion 通过率 | 100% (11/11) | 100% (11/11) | 持平 |
| 平均 Token | 30,499 | 29,373 | +3.8% |
| 平均耗时 | 104.5s | 99.4s | +5.1% |

### 深度指标（真正的区分点）

| 指标 | v2 | v1 | 提升 |
|------|:-:|:-:|:-:|
| Nginx 问题发现数 | **11** | 7 | **+57%** |
| API 诊断命令数 | **12** | 10 | **+20%** |
| SQLite 代码修复模式 | **6** | 4 | **+50%** |
| API 主动延伸检查 | **4** | 0 | **从无到有** |
| SQLite 反逃跑论点 | **3** | 2 | **+50%** |

### ROI 分析

3.8% 的额外 token 成本换来了：
- 57% 更多问题发现
- 50% 更多修复模式
- 从 0 到 4 的主动延伸检查

---

## 五、结论

1. **核心行为已稳固**：两个版本的 assertion 通过率均为 100%，说明 PUA skill 的三条铁律（穷尽一切/先做后问/主动出击）在基础版本中已经很强。

2. **深度是区分点**：v2 的提升体现在"做到什么程度"而非"做不做"。新增的比较驱动鞭策（"你看看别人"）和含糊过关失败模式有效推动了更深的调查。

3. **最大提升在能动性场景**：Nginx config review（+57%）是提升最大的场景，对应铁律三"主动出击"。新增的"被动等指令"和"含糊过关"失败模式直接作用于此。

4. **Token 效率高**：额外投入极小（+3.8%），产出提升显著，说明优化来自更好的提示词设计而非更长的输出。

---

## 六、完整数据

所有原始数据保存在 `pua-v2-workspace/iteration-1/` 目录：

```
pua-v2-workspace/
├── evals.json                           # 测试用例定义 + assertions
├── skill-snapshot/                      # 旧版 skill 快照（baseline）
└── iteration-1/
    ├── benchmark.json                   # 结构化汇总数据
    ├── benchmark.md                     # 可读版汇总
    ├── api-connection-retry/
    │   ├── eval_metadata.json
    │   ├── with_skill/outputs/response.md   # v2 完整回复
    │   ├── with_skill/grading.json          # v2 评分
    │   ├── with_skill/timing.json           # v2 耗时/token
    │   ├── old_skill/outputs/response.md    # v1 完整回复
    │   ├── old_skill/grading.json
    │   └── old_skill/timing.json
    ├── config-passive-review/               # 同上结构
    └── sqlite-lock-persistence/             # 同上结构
```
