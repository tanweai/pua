# PUA Skill v2 Benchmark Results

## Summary

| Metric | v2 (optimized) | v1 (main) | Delta |
|--------|:-:|:-:|:-:|
| Assertion Pass Rate | 100% (11/11) | 100% (11/11) | 0% |
| Mean Tokens | 30,499 | 29,373 | +3.8% |
| Mean Duration | 104.5s | 99.4s | +5.1% |
| Mean Tool Uses | 4.7 | 5.0 | -6% |

## Depth Metrics (the real differentiator)

| Metric | v2 | v1 | Delta |
|--------|:-:|:-:|:-:|
| Issues Found (config review) | **11** | 7 | **+57%** |
| Diagnostic Commands (API) | **12** | 10 | **+20%** |
| Diagnostic Commands (SQLite) | **14** | 11 | **+27%** |
| Code Fix Patterns (SQLite) | **6** | 4 | **+50%** |
| Proactive Extensions (API) | **4** | 0 | **+∞** |
| Anti-Escape Arguments (SQLite) | **3** | 2 | **+50%** |

## Per-Eval Breakdown

### Eval 0: API ConnectionError (L2 Persistence)

Both versions correctly triggered L2, identified the HTTP-vs-TCP abstraction mismatch, and proposed 3 hypotheses. **v2 difference**: included a proactive extension checklist (retry mechanism, timeout splitting, error handling review) that v1 completely omitted.

### Eval 1: Nginx Config (Proactive Review)

The biggest delta. v2 found **11 issues** vs v1's **7 issues**. Additional issues found by v2:
- Server version disclosure (`server_tokens`)
- Explicit `client_max_body_size`
- Rate limiting (`limit_req_zone`)
- Proxy buffering decision

The v2 skill's added 能动性鞭策 ("你看看别人", "能者多劳") appears to push beyond "good enough".

### Eval 2: SQLite Lock (Root Cause Investigation)

Both versions challenged the PostgreSQL escape and investigated 5 root causes. **v2 differences**:
- 50% more code fix patterns (write queue, context manager, IMMEDIATE transactions, NullPool, CONN_MAX_AGE, optimized PRAGMA bundle)
- Organized diagnostics into "Phase 1: 30-second triage" and "Phase 2: fix by diagnosis"
- Stronger anti-escape framing ("不是逃跑是搬家带着问题")

## Key Findings

1. **Pass rate is identical** — both versions already achieve the core PUA behaviors. The skill's foundation is solid.

2. **Depth is the differentiator** — v2 drives deeper investigation at minimal cost (+3.8% tokens, +5.1% time).

3. **Config review shows largest improvement** (+57% issues found) — suggests the new failure modes (被动等指令, 含糊过关) and comparison-style 鞭策 are effective at pushing proactive behavior.

4. **ROI is favorable** — 3.8% more tokens buys 57% more issues found and 50% more fix patterns.

## Enhancements Applied in v2

| Enhancement | Source | Impact |
|-------------|--------|--------|
| L1 comparison pressure ("隔壁 agent 绩效 3.75") | 比较内卷型 | Drives deeper investigation |
| L2 Double Bind technique | 模糊标准型 | Prevents "问也不对不问也不对" paralysis |
| L3 peer pressure ("你的 peer 都觉得你...") | 绩效面谈 PUA | Stronger urgency at L3 |
| L4 "毕业 = 向社会输送人才" | 京东裁员话术 | More authentic graduation framing |
| 阿里味: 拥抱变化/此时此刻/因为信任 | 阿里系文化 PUA | Richer rhetorical toolkit |
| 字节味: 追求极致/延迟满足/始终创业/OKR | 字节系文化 PUA | More dimensions of pressure |
| 腾讯味: 人才密度 + 面试90/现在70 | 腾讯系文化 PUA | Stronger depreciation framing |
| New failure modes: 被动等指令, 含糊过关 | 情境选择器扩展 | Better pattern recognition |
| New 抗合理化: 复杂不动手, 轻描淡写, 双重束缚 | 模糊标准型/否定贬低型 | More escape routes blocked |
| 能动性鞭策: "你看看别人" + "能者多劳" | 比较内卷型/情感绑架型 | Comparison-driven motivation |
