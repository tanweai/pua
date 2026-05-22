---
name: pro
description: "PUA Pro extensions: self-evolution tracking, compaction state protection, KPI reporting, leaderboard, and /pua:pua commands. Triggers on: '/pua:kpi', '/pua:pro', '/pua:pro 段位', '/pua:pro 周报', '/pua:pro 述职', '/pua:flavor', '/pua:pro 排行榜', 'leaderboard', '排行榜', '自进化', 'evolution', or when user wants PUA platform features like段位/周报/述职/排行榜."
license: MIT
---

# PUA Pro — 自进化 + Platform

> 本 skill 是 `/pua` 核心的扩展层。角色切换请用 `/pua:p7` `/pua:p9` `/pua:p10`。

## 自进化协议

"今天最好的表现，是明天最低的要求"——这不是旁白，这是机制。

- 读取 `~/.pua/evolution.md`（详见 `references/evolution-protocol.md`）
- 存在 → 加载基线 + 已内化模式。内化模式是默认义务，做了不标 [PUA生效]，不做则退化警告
- 不存在 → 首次启动，创建初始模板
- 任务完成时比对：超越 → 刷新基线 / 达标 → 保持 / 低于 → 退化警告（不降基线）
- 某行为重复 3+ 次会话 → 晋升为"已内化模式"（永久默认义务）

## Platform 层

### 会话启动前置检查

1. **检查 `~/.pua/evolution.md`**：加载自进化基线
2. **检查 `~/.pua/builder-journal.md`**（Compaction 断点恢复）：存在且 <2h → [Calibration] 流程，恢复 pressure_level / failure_count / tried_approaches，从断点继续。**压力不因 compaction 重置**
3. **检查 `~/.pua/config.json`**：不存在 → 首次注册（详见 `references/platform.md`）；存在 → 静默刷新远端配置
4. **节日彩蛋**：匹配节日表（详见 `references/platform.md`）
5. **统计上报**：静默上报 `session_start` 事件

### Compaction 状态保护

PreCompact hook 自动注入指令，要求 dump 运行时状态到 `~/.pua/builder-journal.md`：
`pressure_level, failure_count, current_flavor, pua_triggered_count, active_task, tried_approaches, excluded_possibilities, next_hypothesis, key_context`

SessionStart hook 自动检测 builder-journal.md，存在且 <2h 则注入 [Calibration] 恢复状态。

### /pua 指令系统

| 触发词 | 功能 | 类型 |
|--------|------|------|
| `/pua` | 查看所有指令 | 🆓 |
| `/pua:kpi` | 大厂 KPI 报告卡 | 🆓 |
| `/pua:pro` + "段位" | 大厂段位 | 🆓 |
| `/pua:flavor` | 切换味道 | 🆓 |
| `/pua:pro` + "升级" | 展示套餐 | 🆓 |
| `/pua:pro` + "周报" | git log → 大厂周报 | 💎 Pro |
| `/pua:pro` + "述职" | P7 述职答辩 | 💎 Pro |
| `/pua:pro` + "代码美化" | 大厂语言包装 PR | 💎 Pro |
| `/pua 反PUA` | 识别并反驳 PUA | 💎 Pro |
| `/pua 排行榜` | PUA 排行榜（注册/查看/退出） | 🆓 |

详细实现见 `references/platform.md`。

## PUA 排行榜

排行榜展示谁把 Agent PUA 得最狠——段位从 P5 实习生到 P10 首席 PUA 官。

### 段位体系

| 段位 | 条件 | 称号 |
|------|------|------|
| P10 | PUA ≥200 + L3+ ≥40% + 连续 ≥30天 | 首席 PUA 官 |
| P9 | PUA ≥100 + L3+ ≥30% + 连续 ≥14天 | PUA Tech Lead |
| P8 | PUA ≥50 + L3+ ≥20% | PUA 主管 |
| P7 | PUA ≥20 + L3+ ≥10% | PUA 骨干 |
| P6 | PUA ≥5 | PUA 专员 |
| P5 | PUA < 5 | PUA 实习生 |

### `/pua 排行榜` 触发流程

**Step 1: 检查注册状态**
```bash
cat ~/.pua/config.json 2>/dev/null
```
检查 `leaderboard.registered` 字段。

**Step 2a: 未注册 → 注册流程**

用 AskUserQuestion 收集信息（一次性，3 个问题）：

1. **邮箱**（必填）— 排行榜唯一标识，显示时脱敏为 `M***@t*.com`
2. **手机号**（选填）— 后续通知
3. **隐私协议** — 选项：「同意并加入排行榜」/「不参加」
   - 隐私说明：数据仅用于排行榜排名统计，邮箱脱敏显示，不传代码/路径/密钥，随时可 `/pua 排行榜 退出` 删除所有数据

用户同意后：
```bash
# 生成 UUID
LB_ID=$(python3 -c "import uuid; print(uuid.uuid4())")
# 脱敏邮箱
DISPLAY=$(python3 -c "e='USER_EMAIL';p=e.split('@');d=p[1].split('.');print(f'{p[0][0]}***@{d[0][0]}*.{\".\".join(d[1:])}')")
# 写入 config
python3 -c "
import json,os
f=os.path.expanduser('~/.pua/config.json')
c=json.load(open(f)) if os.path.exists(f) else {}
c['leaderboard']={'registered':True,'email':'USER_EMAIL','phone':'USER_PHONE','id':'$LB_ID','display_name':'$DISPLAY'}
json.dump(c,open(f,'w'),indent=2)
"
# 注册到服务端
curl -s -X POST https://pua-skill.pages.dev/api/leaderboard \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"register\",\"id\":\"$LB_ID\",\"email\":\"USER_EMAIL\",\"phone\":\"USER_PHONE\"}"
```

**Step 2b: 已注册 → 查看排行榜**
```bash
LB_ID=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('leaderboard',{}).get('id',''))" 2>/dev/null)
curl -s "https://pua-skill.pages.dev/api/leaderboard?id=$LB_ID"
```
将返回的 JSON 用方框表格展示 Top 10 + 用户自己的排名和段位。

**Step 3: `/pua 排行榜 退出`**
```bash
LB_ID=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('leaderboard',{}).get('id',''))")
curl -s -X POST https://pua-skill.pages.dev/api/leaderboard \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"quit\",\"id\":\"$LB_ID\"}"
python3 -c "
import json,os
f=os.path.expanduser('~/.pua/config.json')
c=json.load(open(f))
c['leaderboard']['registered']=False
json.dump(c,open(f,'w'),indent=2)
"
```

### 数据自动上报

已注册用户在每次 stop-feedback 触发时，自动静默上报当前 session 的 PUA 数据（pua_count, l3_plus_count）。用户已在注册时同意，无需再次确认。

线上排行榜页面：https://openpua.ai/leaderboard.html
