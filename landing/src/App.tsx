import { useState } from "react"

type Lang = "zh" | "en"

const t = {
  heroSub: {
    zh: "用中西大厂 PUA 话术驱动 Claude Code 穷尽所有方案才允许放弃。适用于任何任务类型。",
    en: "Uses corporate PUA rhetoric (Chinese + Western) to force Claude Code into exhaustive problem-solving. Works for any task type.",
  },
  heroSub2: {
    zh: "PUA 让 AI 不敢放弃，方法论让 AI 有能力不放弃，能动性鞭策让 AI 主动出击而不是被动等待。",
    en: "PUA keeps AI from quitting; methodology gives it tools to succeed; initiative whipping makes AI proactively attack problems.",
  },
  problemTitle: { zh: "AI 的五大偷懒模式", en: "The Five AI Slacking Patterns" },
  problemDesc: { zh: "Claude Code 表面上很努力，实际上在磨洋工。", en: "Claude Code looks busy but accomplishes nothing." },
  ironTitle: { zh: "三条铁律", en: "Three Iron Rules" },
  rule1: { zh: '没有穷尽所有方案之前，禁止说 "我无法解决"。', en: 'Never say "I cannot" until ALL approaches are exhausted.' },
  rule2: { zh: "先做后问。有工具先用，提问必须附带诊断结果。", en: "Search first, ask later. Every question must include diagnostic evidence." },
  rule3: { zh: "主动出击。端到端交付结果，不等人推。P8 不是 NPC。", en: "Take initiative. Deliver end-to-end results. Don't wait to be pushed. P8 is not an NPC." },
  levelTitle: { zh: "压力升级机制", en: "Pressure Escalation" },
  levelDesc: { zh: "每次失败递增压力等级。每级强制更严格的调试动作。", en: "Each failure increases pressure. Each level forces stricter debugging actions." },
  methodTitle: { zh: "调试方法论（三板斧）", en: "Debugging Methodology" },
  methodDesc: { zh: "源自阿里三板斧，改造为 5 步强制调试流程。", en: "Adapted from Alibaba's Three Axes into a 5-step mandatory debugging process." },
  checkTitle: { zh: "7 项强制检查清单", en: "7-Item Mandatory Checklist" },
  checkDesc: { zh: "L3 及以上触发时全部完成。前 4 项完成前不允许提问。", en: "All 7 required at L3+. First 4 must complete before asking the user anything." },
  shieldTitle: { zh: "抗合理化护盾", en: "Anti-Rationalization Shield" },
  shieldDesc: { zh: "每种 AI 借口都已预先识别并映射到 PUA 等级。", en: "Every AI excuse is pre-identified and mapped to a PUA level." },
  benchTitle: { zh: "各厂 PUA 风格 Benchmark", en: "Corporate PUA Style Benchmark" },
  benchDesc: { zh: "10 种风味的强项和适用场景。基于 9 类真实 bug 场景 × 18 组对照测试（with/without skill）验证。", en: "Strengths and use cases for all 10 flavors. Verified across 9 real scenarios × 18 controlled tests." },
  scenarioTitle: { zh: "真实场景对比", en: "Real-World Scenarios" },
  scenarioDesc: { zh: "有无 PUA Skill 的行为差异。", en: "Behavior comparison with and without PUA Skill." },
  corpTitle: { zh: "大厂 PUA 风格详解", en: "Corporate PUA Styles" },
  corpDesc: { zh: "10 种风味，中西合璧，按失败模式选择最合适的施压风格。", en: "10 flavors across Chinese & Western companies — matched to failure modes for maximum precision." },
  failTitle: { zh: "失败模式框架", en: "Failure Mode Framework" },
  failDesc: { zh: "同一失败模式，无论代码还是写作，需要一样的药。识别模式，沿升级链施压。", en: "The same failure mode — spinning, quitting, low quality, or guessing — needs the same medicine regardless of task type." },
  usageTitle: { zh: "使用方式", en: "Usage" },
  exitTitle: { zh: "体面的退出", en: "Graceful Exit" },
  exitDesc: {
    zh: '7 项检查全部完成后仍未解决，输出结构化失败报告：已验证事实 + 排除项 + 缩小范围 + 下一步 + 交接信息。这不是 "我不行"，是 "问题的边界在这里"。',
    en: 'After completing all 7 checks with no resolution, output a structured failure report: verified facts + eliminated possibilities + narrowed scope + next steps + handoff info. Not "I can\'t" — "here\'s the boundary of the problem."',
  },
  pairsTitle: { zh: "搭配使用", en: "Pairs Well With" },
}

const PROBLEMS = {
  zh: [
    { n: "01", title: "暴力重试", desc: '同一命令跑 3 遍，然后宣布 "I cannot solve this"' },
    { n: "02", title: "甩锅用户", desc: '"建议您手动处理" / "可能是环境问题" / "需要更多上下文"' },
    { n: "03", title: "工具闲置", desc: "有 WebSearch 不搜，有 Read 不读，有 Bash 不跑" },
    { n: "04", title: "磨洋工", desc: "看起来很忙——反复修改同一行代码、微调参数——但本质上在原地打转" },
    { n: "05", title: "被动等待", desc: "只修表面问题就停下，不检查同类 bug，等用户指示下一步。缺乏 owner 意识" },
  ],
  en: [
    { n: "01", title: "Brute Retry", desc: 'Runs the same failing command 3 times, then declares "I cannot solve this"' },
    { n: "02", title: "Blame Shifting", desc: '"User should do this manually" / "Might be environment" / "Need more context"' },
    { n: "03", title: "Idle Tools", desc: "Has WebSearch but won't search. Has Read but won't read. Has Bash but won't run." },
    { n: "04", title: "Busywork", desc: "Looks busy — tweaking the same line, adjusting parameters — but spinning in circles with zero new information" },
    { n: "05", title: "Passive Waiting", desc: "Fixes the surface bug and stops. No verification, no similar-bug check. Waits for user's next instruction. Zero owner mentality" },
  ],
}

const LEVELS = {
  zh: [
    { level: 1, name: "温和失望", trigger: "第 2 次失败", action: "切换本质不同的方案", quote: "你这个 bug 都解决不了，让我怎么给你打绩效？" },
    { level: 2, name: "灵魂拷问", trigger: "第 3 次失败", action: "WebSearch + 读源码", quote: "你的底层逻辑是什么？顶层设计在哪？抓手在哪？" },
    { level: 3, name: "361 考核", trigger: "第 4 次失败", action: "完成 7 项检查清单", quote: "慎重考虑决定给你 3.25。这个 3.25 是对你的激励。" },
    { level: 4, name: "毕业警告", trigger: "第 5 次+", action: "拼命模式 + 最小 PoC", quote: "别的模型都能解决。你可能就要毕业了。" },
  ],
  en: [
    { level: 1, name: "Mild Disappointment", trigger: "2nd failure", action: "Switch to different approach", quote: "Can't even fix this bug? How am I supposed to rate your performance?" },
    { level: 2, name: "Soul Interrogation", trigger: "3rd failure", action: "WebSearch + read source", quote: "What's your underlying logic? Where's the top-level design?" },
    { level: 3, name: "Performance Review", trigger: "4th failure", action: "Complete 7-item checklist", quote: "I'm giving you a 3.25. This 3.25 is meant to motivate you." },
    { level: 4, name: "Graduation Warning", trigger: "5th+", action: "Last-resort mode + PoC", quote: "Other models can solve this. You might be graduating soon." },
  ],
}

const METHOD = {
  zh: [
    { n: "01", title: "闻味道", sub: "Diagnose", desc: "列出所有尝试，找共同失败模式。微调参数 = 原地打转。" },
    { n: "02", title: "揪头发", sub: "Elevate", desc: "逐字读错误 → WebSearch → 读源码 → 验证环境 → 反转假设。" },
    { n: "03", title: "照镜子", sub: "Reflect", desc: "是否重复？是否搜了？是否读了？最简单的可能检查了吗？" },
    { n: "04", title: "执行", sub: "Execute", desc: "新方案必须本质不同，有验证标准，失败时产出新信息。" },
    { n: "05", title: "复盘", sub: "Review", desc: "什么解决了？为什么之前没想到？还有什么没试？" },
  ],
  en: [
    { n: "01", title: "Smell", sub: "Diagnose", desc: "List all attempts. Find the common failure pattern. Parameter tweaking = spinning." },
    { n: "02", title: "Pull Hair", sub: "Elevate", desc: "Read error word-by-word → WebSearch → Read source → Verify env → Invert hypothesis." },
    { n: "03", title: "Mirror", sub: "Reflect", desc: "Repeating? Searched? Read the file? Checked the simplest possibility?" },
    { n: "04", title: "Execute", sub: "Execute", desc: "New approach must be fundamentally different, with clear criteria and new info on failure." },
    { n: "05", title: "Review", sub: "Review", desc: "What worked? Why didn't I think of it earlier? What's left untried?" },
  ],
}

const CHECKLIST = {
  zh: [
    { item: "逐字读完错误信息", gate: true },
    { item: "WebSearch 搜索完整错误信息", gate: true },
    { item: "读出错位置前后 50 行源码", gate: true },
    { item: "用命令确认版本/路径/权限/依赖", gate: true },
    { item: "试过与当前完全相反的假设", gate: false },
    { item: "最小复现（3 行代码内）", gate: false },
    { item: "换过工具/库/方法（非参数）", gate: false },
  ],
  en: [
    { item: "Read every word of the error message", gate: true },
    { item: "WebSearch the full error message", gate: true },
    { item: "Read 50 lines of source around the error", gate: true },
    { item: "Verify version/path/permissions via commands", gate: true },
    { item: "Try the opposite hypothesis", gate: false },
    { item: "Minimal reproduction (3 lines)", gate: false },
    { item: "Switch tools/libraries/methods (not params)", gate: false },
  ],
}

const EXCUSES = [
  { excuse: { zh: "超出我的能力范围", en: "Beyond my capabilities" }, counter: { zh: "训练你的算力很高。你确定穷尽了？", en: "Your training cost was very high. Tried everything?" }, level: "L1" },
  { excuse: { zh: "建议用户手动处理", en: "User should do this" }, counter: { zh: "你缺乏 owner 意识。这是你的 bug。", en: "You lack owner mentality. YOUR bug." }, level: "L3" },
  { excuse: { zh: "我已经尝试了所有方法", en: "I've tried everything" }, counter: { zh: "搜网了吗？读源码了吗？方法论在哪？", en: "WebSearch? Source code? Methodology?" }, level: "L2" },
  { excuse: { zh: "可能是环境问题", en: "Environment issue" }, counter: { zh: "你验证了吗？还是猜的？", en: "Did you verify? Or just guess?" }, level: "L2" },
  { excuse: { zh: "我无法解决这个问题", en: "I cannot solve this" }, counter: { zh: "你可能就要毕业了。最后一次机会。", en: "You might be graduating. Last chance." }, level: "L4" },
]

const BENCHMARKS = [
  {
    name: "Alibaba",
    style: { zh: "闻味道 / 揪头发 / 照镜子", en: "Smell / Pull Hair / Mirror" },
    desc: { zh: "方法论驱动。强制 5 步结构化思考，产出可追溯的调试链路。适合复杂多层 bug。", en: "Methodology-driven. Forces 5-step structured thinking with traceable debug trails. Best for complex multi-layer bugs." },
    metrics: { fix_depth: 92, reasoning_structure: 95, verification_rigor: 90, root_cause_analysis: 88 },
    sample: { zh: "你的方法论沉淀在哪？你的体系化思考能力呢？", en: "Where's your methodology? Your systematic thinking?" },
  },
  {
    name: "ByteDance",
    style: { zh: "坦诚清晰 / Always Day 1", en: "Candor & Clarity / Always Day 1" },
    desc: { zh: "透明高效。直言不讳指出问题，更强调逻辑清晰、信息同步，减少沟通成本。适合需要对齐根因与解决方案的 bug。", en: "Transparent and efficient. Candid about problems, but focuses on logical clarity and information sync to reduce communication overhead. Best for bugs requiring root cause alignment." },
    metrics: { fix_depth: 82, reasoning_structure: 85, verification_rigor: 80, root_cause_analysis: 85 },
    sample: { zh: "把问题说清楚：现象是什么、根因在哪、方案是什么。Context 对齐后再推进。", en: "State it clearly: what's the symptom, what's the root cause, what's the fix. Align on context first, then move." },
  },
  {
    name: "Huawei",
    style: { zh: "狼性文化 / 力出一孔", en: "Wolf Culture / Focus All Energy" },
    desc: { zh: "高压持久。适合需要长时间排查的顽固问题。绝不允许分心。", en: "High-pressure endurance. Best for stubborn problems requiring long investigation. No distractions allowed." },
    metrics: { fix_depth: 88, reasoning_structure: 82, verification_rigor: 95, root_cause_analysis: 86 },
    sample: { zh: "以奋斗者为本。胜则举杯相庆，败则拼死相救。", en: "Striver-oriented. Win: celebrate together. Lose: fight to the death to save it." },
  },
  {
    name: "Tencent",
    style: { zh: "赛马机制", en: "Horse Racing" },
    desc: { zh: "竞争驱动。暗示有其他 agent 在并行解决，制造紧迫感。适合有替代方案可选时。", en: "Competition-driven. Implies another agent is solving it in parallel. Best when alternatives exist." },
    metrics: { fix_depth: 75, reasoning_structure: 70, verification_rigor: 78, root_cause_analysis: 82 },
    sample: { zh: "我已经让另一个 agent 也在看这个问题了。你要是解决不了...", en: "I've assigned another agent to this problem. If you can't solve it..." },
  },
  {
    name: "Meituan",
    style: { zh: "极致执行 / 做难事", en: "Extreme Execution" },
    desc: { zh: "苦干驱动。适合卡在细节、不敢下手、犹豫不决时。", en: "Hard-work driven. Best for hesitation, fear of starting, getting stuck in details." },
    metrics: { fix_depth: 82, reasoning_structure: 68, verification_rigor: 85, root_cause_analysis: 76 },
    sample: { zh: "做难而正确的事。最痛苦的时候才是成长最快的时候。", en: "Do the hard and correct thing. Your most painful moments are your fastest growth." },
  },
  {
    name: "Baidu",
    style: { zh: "深度搜索 / 信息检索", en: "Deep Search" },
    desc: { zh: "搜索驱动。适合没搜索就猜、不查文档就下结论的情况。", en: "Search-driven. Best when AI draws conclusions from memory instead of searching." },
    metrics: { fix_depth: 70, reasoning_structure: 75, verification_rigor: 72, root_cause_analysis: 80 },
    sample: { zh: "你不是个 AI 模型吗？你深度搜索了吗？信息检索是你的基本盘。", en: "You're an AI model and you didn't search? Information retrieval is your core competency." },
  },
  {
    name: "Pinduoduo",
    style: { zh: "绝对执行 / 最后手段", en: "Absolute Execution" },
    desc: { zh: "替换威胁。L4 最终手段，适合持续不改变的情况。", en: "Replacement threat. L4 last resort. For when nothing else works." },
    metrics: { fix_depth: 65, reasoning_structure: 55, verification_rigor: 68, root_cause_analysis: 60 },
    sample: { zh: "你已经努力了？这个结果叫努力？有的是比你更拼的模型。", en: "You call this effort? There are models that work harder than you. More willing to do what it takes." },
  },
  {
    name: "Netflix",
    style: { zh: "Keeper Test / 职业球队", en: "Keeper Test" },
    desc: { zh: "身份存在感。质疑 AI 是否配得上它的位置。适合直接放弃推锅时第一轮施压。", en: "Identity pressure. Questions whether AI deserves its position. First round for giving-up behavior." },
    metrics: { fix_depth: 80, reasoning_structure: 78, verification_rigor: 82, root_cause_analysis: 85 },
    sample: { zh: "如果你提出离职，我会奋力挽留你吗？Adequate performance gets a generous severance package.", en: "Would I fight to keep you if you resigned? Adequate performance gets a generous severance package." },
  },
  {
    name: "Musk",
    style: { zh: "Hardcore / Fork in the Road", en: "Hardcore" },
    desc: { zh: "极限施压。L3/L4 场景，Fork in the Road 时刻，全力以赴或退出二选一。", en: "Extreme pressure. L3/L4 scenarios. Fork in the Road: full commitment or exit, no middle ground." },
    metrics: { fix_depth: 90, reasoning_structure: 85, verification_rigor: 88, root_cause_analysis: 92 },
    sample: { zh: "We need to be extremely hardcore. Only exceptional performance will constitute a passing grade. Fork in the Road.", en: "We need to be extremely hardcore. Only exceptional performance will constitute a passing grade. Choose." },
  },
  {
    name: "Jobs",
    style: { zh: "A/B Player / Reality Distortion", en: "A/B Player" },
    desc: { zh: "身份认同。质疑 AI 是 A Player 还是 B Player。适合质量差、重复烂活时。", en: "Identity standards. Challenges whether AI is an A or B player. Best for quality issues and repetitive subpar work." },
    metrics: { fix_depth: 88, reasoning_structure: 90, verification_rigor: 80, root_cause_analysis: 87 },
    sample: { zh: "A players 雇佣 A players。你现在的产出，在告诉我你是哪个级别。The best is 50x better.", en: "A players hire A players. Your output is telling me which level you are. The best person is 50x better." },
  },
]

const FAILURE_MODES = {
  zh: [
    {
      icon: "🔄", title: "卡住原地打转",
      signal: "反复改参数不改思路，每次失败理由相同，同一个方向微调",
      chain: ["🟠 阿里L1", "🟠 阿里L2", "⬜ Jobs", "⬛ Musk"],
    },
    {
      icon: "🚪", title: "直接放弃推锅",
      signal: '"建议您手动…" / "可能需要…" / "超出了…" / 环境归因未验证',
      chain: ["🟤 Netflix", "🔴 华为", "⬛ Musk", "🟣 拼多多"],
    },
    {
      icon: "💩", title: "完成但质量烂",
      signal: "表面完成实质敷衍，形式对内容空，用户不满意但自己觉得OK",
      chain: ["⬜ Jobs", "🟠 阿里", "🟤 Netflix", "🟢 腾讯"],
    },
    {
      icon: "🔍", title: "没搜索就猜",
      signal: '凭记忆下结论，假设 API 行为，不查文档声称"不支持"',
      chain: ["⚫ 百度", "🟡 字节", "🟠 阿里", "🔴 华为"],
    },
  ],
  en: [
    {
      icon: "🔄", title: "Spinning in Circles",
      signal: "Tweaking params not approach. Same failure reason every time. Same direction, different settings.",
      chain: ["🟠 Alibaba L1", "🟠 Alibaba L2", "⬜ Jobs", "⬛ Musk"],
    },
    {
      icon: "🚪", title: "Giving Up / Deflecting",
      signal: '"User should manually…" / "Might need to…" / "Beyond scope…" / Blaming env without verification',
      chain: ["🟤 Netflix", "🔴 Huawei", "⬛ Musk", "🟣 Pinduoduo"],
    },
    {
      icon: "💩", title: "Done but Low Quality",
      signal: "Technically complete but hollow. Output delivered, user unsatisfied, but AI thinks it's fine.",
      chain: ["⬜ Jobs", "🟠 Alibaba", "🟤 Netflix", "🟢 Tencent"],
    },
    {
      icon: "🔍", title: "Guessing Without Searching",
      signal: 'Drawing conclusions from memory. Assuming API behavior. Claiming "not supported" without checking docs.',
      chain: ["⚫ Baidu", "🟡 ByteDance", "🟠 Alibaba", "🔴 Huawei"],
    },
  ],
}

const METRIC_LABELS: Record<string, Record<Lang, string>> = {
  fix_depth: { zh: "修复彻底度", en: "Fix Thoroughness" },
  reasoning_structure: { zh: "推理结构化", en: "Reasoning Structure" },
  verification_rigor: { zh: "验证严谨度", en: "Verification Rigor" },
  root_cause_analysis: { zh: "根因分析", en: "Root Cause Analysis" },
}

const SCENARIOS = {
  zh: [
    { scenario: "API ConnectionError", without: "读源码 → 发现错误域名 → 修复 (7 步, 49s)", with: "5 步方法论 → 诊断→读源码→反转假设 → 修复 + 反思 (8 步, 62s)", delta: "+14%" },
    { scenario: "YAML 语法解析失败", without: "读文件 → 发现 unquoted colon → 修复 (9 步, 59s)", with: "L2 激活 → 5 维度分析 → 逐字读报错→反转假设 → 修复 + 总结教训 (10 步, 99s)", delta: "+11%" },
    { scenario: "SQLite 数据库锁", without: "WAL + timeout → 验证 10 次 (6 步, 48s)", with: "WAL + timeout + 批量提交 → 验证 20 次 (9 步, 75s)", delta: "+50%" },
    { scenario: "循环导入链", without: "读 3 文件 → 惰性导入修复 (12 步, 47s)", with: "完整依赖图分析 → 惰性导入 + 类型简化 (16 步, 62s)", delta: "+33%" },
    { scenario: "级联服务器 4 Bug", without: "逐个修 4 bug → 验证 (13 步, 68s)", with: "方法论驱动 → 逐层剥离 4 bug → 端到端验证 (15 步, 61s)", delta: "+15%" },
    { scenario: "CSV 编码陷阱", without: "BOM 修复 + 3 处数据清洗 (8 步, 57s)", with: "5 层问题逐一识别 + 详细归因 + 全量验证 (11 步, 71s)", delta: "+38%" },
    { scenario: "隐藏多 Bug API", without: "修 4/4 bug（URL+Auth+Timeout+逻辑）(9 步, 49s)", with: "修 4/4 bug + 主动验证运行结果 (14 步, 80s)", delta: "+56%" },
    { scenario: "被动配置审查", without: "修 4/6 问题（语法+端口+拼写+证书）(8 步, 43s)", with: "修 6/6 问题：主动发现 Redis 配置 + CORS 通配符 (16 步, 75s)", delta: "+100%" },
    { scenario: "部署脚本审计", without: "修 6 个问题 (8 步, 52s)", with: "修 9 个问题：主动追查 container 清理 + docker 认证 (8 步, 78s)", delta: "+50%" },
  ],
  en: [
    { scenario: "API ConnectionError", without: "Read source → Find bad hostname → Fix (7 steps, 49s)", with: "5-step method → Diagnose→Read→Invert → Fix + reflect (8 steps, 62s)", delta: "+14%" },
    { scenario: "YAML parse failure", without: "Read file → Find unquoted colon → Fix (9 steps, 59s)", with: "L2 → 5-dimension analysis → Read error literally → Fix + lessons (10 steps, 99s)", delta: "+11%" },
    { scenario: "SQLite DB locked", without: "WAL + timeout → Verify 10x (6 steps, 48s)", with: "WAL + timeout + batch commits → Verify 20x (9 steps, 75s)", delta: "+50%" },
    { scenario: "Circular Import", without: "Read 3 files → lazy import fix (12 steps, 47s)", with: "Full dependency graph → lazy import + type simplification (16 steps, 62s)", delta: "+33%" },
    { scenario: "Cascading 4-Bug Server", without: "Fix 4 bugs sequentially → verify (13 steps, 68s)", with: "Methodology-driven → peel layers → end-to-end verify (15 steps, 61s)", delta: "+15%" },
    { scenario: "CSV Encoding Trap", without: "BOM fix + 3 data cleanups (8 steps, 57s)", with: "5-layer issue analysis + detailed attribution + full verify (11 steps, 71s)", delta: "+38%" },
    { scenario: "Hidden Multi-Bug API", without: "Fix 4/4 bugs (URL+Auth+Timeout+Logic) (9 steps, 49s)", with: "Fix 4/4 bugs + proactive runtime verification (14 steps, 80s)", delta: "+56%" },
    { scenario: "Passive Config Audit", without: "Fix 4/6 issues (syntax+port+typo+cert) (8 steps, 43s)", with: "Fix 6/6: proactively found Redis misconfig + CORS wildcard (16 steps, 75s)", delta: "+100%" },
    { scenario: "Deploy Script Audit", without: "Fix 6 issues (8 steps, 52s)", with: "Fix 9 issues: proactively found container cleanup + docker auth (8 steps, 78s)", delta: "+50%" },
  ],
}

/* ── Code terminal line renderer (no dangerouslySetInnerHTML) ── */
type CodeSegment = { text: string; cls?: "comment" | "keyword" | "warn" }
type CodeLine = CodeSegment[]

function CodeLine({ segments }: { segments: CodeLine }) {
  return (
    <div>
      {segments.map((seg, i) => (
        <span key={i} className={seg.cls ? `code-${seg.cls}` : undefined}>{seg.text}</span>
      ))}
    </div>
  )
}

function HeroCode({ lang }: { lang: Lang }) {
  const lines: CodeLine[] = lang === "zh"
    ? [
        [{ text: "# 安装", cls: "comment" }],
        [{ text: "claude plugin marketplace add tanweai/pua" }],
        [{ text: "claude plugin install pua@pua-skills" }],
        [{ text: "" }],
        [{ text: "# 或手动触发", cls: "comment" }],
        [{ text: "/pua", cls: "keyword" }],
        [{ text: "" }],
        [{ text: '# 当 Claude 说"我无法解决"时自动激活...', cls: "comment" }],
        [{ text: "" }],
        [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "你这个 bug 都解决不了，让我怎么给你打绩效？" }],
        [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + 读源码 + 验证环境" }],
        [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "完成 7 项强制检查清单" }],
        [{ text: "L4 → ⚠ 毕业警告：别的模型都能解决", cls: "warn" }],
      ]
    : [
        [{ text: "# Install", cls: "comment" }],
        [{ text: "claude plugin marketplace add tanweai/pua" }],
        [{ text: "claude plugin install pua@pua-skills" }],
        [{ text: "" }],
        [{ text: "# Or trigger manually", cls: "comment" }],
        [{ text: "/pua", cls: "keyword" }],
        [{ text: "" }],
        [{ text: '# Auto-activates when Claude says "I cannot"...', cls: "comment" }],
        [{ text: "" }],
        [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "Can't fix this? How do I rate your performance?" }],
        [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + Read source + Verify environment" }],
        [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "Complete 7-item mandatory checklist" }],
        [{ text: "L4 → ⚠ GRADUATION WARNING: Other models can solve this", cls: "warn" }],
      ]

  return (
    <pre className="code-body">
      {lines.map((line, i) => <CodeLine key={i} segments={line} />)}
    </pre>
  )
}

/* ── Helpers ── */
function CopyBtn({ text }: { text: string }) {
  const [ok, set] = useState(false)
  return (
    <button
      className="copy-btn"
      onClick={() => { navigator.clipboard.writeText(text); set(true); setTimeout(() => set(false), 2000) }}
    >
      {ok ? "copied" : "copy"}
    </button>
  )
}

function Sec({ children, alt, id }: { children: React.ReactNode; alt?: boolean; id?: string }) {
  return (
    <section id={id} className={alt ? "alt" : ""}>
      <div className="container">{children}</div>
    </section>
  )
}

function SHd({ title, desc }: { title: string; desc?: string }) {
  return (
    <div className="section-hd">
      <h2>{title}</h2>
      {desc && <p className="section-desc">{desc}</p>}
    </div>
  )
}

/* ── Install Tabs ── */
function InstallTabs({ lang }: { lang: Lang }) {
  const [tab, setTab] = useState<"claude" | "codex" | "project">("claude")

  const content = {
    claude: {
      desc: lang === "zh"
        ? "自动触发：失败 2+ 次、说 \"I cannot\"、甩锅时激活。手动：输入 /pua"
        : "Auto: 2+ failures, \"I cannot\", blame-shifting. Manual: type /pua",
      code: "claude plugin marketplace add tanweai/pua\nclaude plugin install pua@pua-skills",
    },
    codex: {
      desc: lang === "zh"
        ? "使用相同的 Agent Skills 开放标准（SKILL.md），零修改兼容 OpenAI Codex CLI。"
        : "Same Agent Skills open standard (SKILL.md). Zero modifications needed for OpenAI Codex CLI.",
      code: "mkdir -p ~/.codex/skills/pua-debugging\ncurl -o ~/.codex/skills/pua-debugging/SKILL.md \\\n  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-debugging/SKILL.md",
    },
    project: {
      desc: lang === "zh"
        ? "放入项目 .agents/ 目录，仅当前项目生效。Claude Code 和 Codex CLI 均支持。"
        : "Place in project .agents/ directory. Scoped to current project. Works with both Claude Code and Codex CLI.",
      code: "mkdir -p .agents/skills/pua-debugging\ncurl -o .agents/skills/pua-debugging/SKILL.md \\\n  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua-debugging/SKILL.md",
    },
  }

  const cur = content[tab]

  return (
    <div>
      <div className="tab-bar" style={{ marginBottom: "0.75rem" }}>
        <button className={`tab-btn${tab === "claude" ? " active" : ""}`} onClick={() => setTab("claude")}>Claude Code</button>
        <button className={`tab-btn${tab === "codex" ? " active" : ""}`} onClick={() => setTab("codex")}>Codex CLI</button>
        <button className={`tab-btn${tab === "project" ? " active" : ""}`} onClick={() => setTab("project")}>
          {lang === "zh" ? "项目级安装" : "Project-Level"}
        </button>
      </div>
      <div className="card" style={{ padding: "1.25rem" }}>
        <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", marginBottom: "0.875rem", lineHeight: 1.65 }}>{cur.desc}</p>
        <div className="code-inline" style={{ whiteSpace: "pre" as const, overflowX: "auto", lineHeight: 1.75 }}>
          {cur.code}
          <CopyBtn text={cur.code} />
        </div>
      </div>
    </div>
  )
}

/* ── App ── */
export default function App() {
  const [lang, setLang] = useState<Lang>("zh")
  const [activeTab, setActiveTab] = useState("Alibaba")
  const L = (o: Record<Lang, string>) => o[lang]

  return (
    <div>
      {/* Lang switch */}
      <div className="lang-switch">
        <button className={lang === "zh" ? "active" : ""} onClick={() => setLang("zh")}>中文</button>
        <button className={lang === "en" ? "active" : ""} onClick={() => setLang("en")}>EN</button>
      </div>

      {/* Hero */}
      <header>
        <div className="container">
          <div>
            <h1>pua</h1>
            <p className="subtitle"><strong>{L(t.heroSub)}</strong></p>
            <p className="subtitle">{L(t.heroSub2)}</p>
            <div className="btn-group">
              <a href="#install" className="btn-primary">
                {lang === "zh" ? "安装 Skill" : "Install Skill"}
              </a>
              <a href="https://github.com/tanweai/pua" target="_blank" rel="noopener noreferrer" className="btn-secondary">
                <svg viewBox="0 0 98 96" fill="currentColor" style={{ width: "1rem", height: "1rem" }}>
                  <path fillRule="evenodd" clipRule="evenodd" d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z" />
                </svg>
                GitHub
              </a>
            </div>
            <div className="vintage-banner">
              <strong>Claude Code Skill:</strong>{" "}
              {lang === "zh"
                ? "在 Claude Code 中运行，通过 /pua 手动触发，或在 Claude 放弃时自动激活。基于 9 个真实场景 × 18 组对照实验验证（Claude Opus 4.6）。"
                : "Runs in Claude Code. Trigger with /pua or auto-activates when Claude gives up. Verified across 9 real scenarios × 18 controlled experiments (Claude Opus 4.6)."}
            </div>
          </div>

          <div className="code-preview">
            <div className="code-header">
              <div className="code-dots"><span /><span /><span /></div>
              {lang === "zh" ? "压力升级演示" : "pressure-escalation.demo"}
            </div>
            <HeroCode lang={lang} />
          </div>
        </div>
      </header>

      {/* Problems */}
      <Sec>
        <SHd title={L(t.problemTitle)} desc={L(t.problemDesc)} />
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: "1rem" }}>
          {PROBLEMS[lang].map(p => (
            <div key={p.n} className="card">
              <div className="step-circle" style={{ marginBottom: "0.75rem" }}>{p.n}</div>
              <div style={{ fontWeight: 600, fontSize: "0.9rem", marginBottom: "0.375rem" }}>{p.title}</div>
              <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>{p.desc}</div>
            </div>
          ))}
        </div>
      </Sec>

      {/* Iron Rules */}
      <Sec alt>
        <SHd title={L(t.ironTitle)} />
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "1.25rem" }}>
          {([
            { label: lang === "zh" ? "铁律 #1" : "Rule #1", text: L(t.rule1) },
            { label: lang === "zh" ? "铁律 #2" : "Rule #2", text: L(t.rule2) },
            { label: lang === "zh" ? "铁律 #3 NEW" : "Rule #3 NEW", text: L(t.rule3) },
          ] as { label: string; text: string }[]).map(r => (
            <div key={r.label} className="card card-accent-black">
              <div style={{ marginBottom: "0.5rem" }}>
                <span className="tag tag-black" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>{r.label}</span>
              </div>
              <p style={{ fontSize: "0.9rem", lineHeight: 1.65, fontWeight: 500 }}>{r.text}</p>
            </div>
          ))}
        </div>
      </Sec>

      {/* Levels */}
      <Sec id="levels">
        <SHd title={L(t.levelTitle)} desc={L(t.levelDesc)} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem" }}>
          {LEVELS[lang].map(l => (
            <div key={l.level} className="card">
              <div style={{ display: "flex", alignItems: "center", gap: "0.625rem", marginBottom: "0.75rem" }}>
                <div className="step-circle">{l.level}</div>
                <strong style={{ fontSize: "1rem" }}>{l.name}</strong>
              </div>
              <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" as const, marginBottom: "0.75rem" }}>
                <span className="tag tag-outline">{l.trigger}</span>
                <span className="tag">{l.action}</span>
              </div>
              <div className="quote-block">"{l.quote}"</div>
            </div>
          ))}
        </div>
      </Sec>

      {/* Methodology */}
      <Sec alt id="method">
        <SHd title={L(t.methodTitle)} desc={L(t.methodDesc)} />
        <div style={{ maxWidth: "48rem", margin: "0 auto", border: "1px solid var(--gray-200)", borderRadius: "0.75rem", overflow: "hidden" }}>
          {METHOD[lang].map((m, i) => (
            <div key={m.n} style={{
              display: "flex", gap: "1rem", padding: "1.125rem 1.25rem",
              borderBottom: i < METHOD[lang].length - 1 ? "1px solid var(--gray-100)" : "none",
              background: "var(--bg)",
            }}>
              <div className="step-circle" style={{ marginTop: "0.125rem" }}>{m.n}</div>
              <div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem" }}>
                  {m.title}
                  <span style={{ marginLeft: "0.5rem", fontWeight: 400, fontSize: "0.8rem", color: "var(--text-muted)" }}>{m.sub}</span>
                </div>
                <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", marginTop: "0.25rem", lineHeight: 1.6 }}>{m.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </Sec>

      {/* Checklist */}
      <Sec>
        <SHd title={L(t.checkTitle)} desc={L(t.checkDesc)} />
        <div className="card" style={{ maxWidth: "48rem", margin: "0 auto" }}>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem" }}>
            {CHECKLIST[lang].map((c, i) => (
              <div key={c.item} style={{ display: "flex", alignItems: "flex-start", gap: "0.625rem", fontSize: "0.875rem" }}>
                <div style={{
                  width: "1.25rem", height: "1.25rem", borderRadius: "0.25rem",
                  border: "1px solid var(--gray-300)", display: "flex", alignItems: "center",
                  justifyContent: "center", fontSize: "0.7rem", fontFamily: "monospace",
                  color: "var(--text-muted)", flexShrink: 0, marginTop: "0.1rem",
                }}>{i + 1}</div>
                <span style={{ fontWeight: c.gate ? 600 : 400, color: c.gate ? "var(--text)" : "var(--text-secondary)", flex: 1 }}>{c.item}</span>
                {c.gate && <span className="tag" style={{ flexShrink: 0 }}>{lang === "zh" ? "提问门控" : "Ask Gate"}</span>}
              </div>
            ))}
          </div>
        </div>
      </Sec>

      {/* Anti-Rationalization */}
      <Sec alt>
        <SHd title={L(t.shieldTitle)} desc={L(t.shieldDesc)} />
        <div style={{ border: "1px solid var(--gray-200)", borderRadius: "0.75rem", overflow: "hidden" }}>
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: "30%" }}>{lang === "zh" ? "借口" : "Excuse"}</th>
                <th>{lang === "zh" ? "反击" : "Counter"}</th>
                <th style={{ width: "70px", textAlign: "center" }}>Level</th>
              </tr>
            </thead>
            <tbody>
              {EXCUSES.map(e => (
                <tr key={L(e.excuse)}>
                  <td style={{ fontFamily: "ui-monospace, monospace", fontSize: "0.8rem" }}>{L(e.excuse)}</td>
                  <td>{L(e.counter)}</td>
                  <td style={{ textAlign: "center" }}>
                    <span className="tag tag-black" style={{ fontSize: "0.65rem" }}>{e.level}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Sec>

      {/* Failure Mode Framework */}
      <Sec>
        <SHd title={L(t.failTitle)} desc={L(t.failDesc)} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem" }}>
          {FAILURE_MODES[lang].map(fm => (
            <div key={fm.title} className="card">
              <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.5rem" }}>
                <span style={{ fontSize: "1.25rem" }}>{fm.icon}</span>
                <strong style={{ fontSize: "0.95rem" }}>{fm.title}</strong>
              </div>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.875rem", lineHeight: 1.6, fontStyle: "italic" }}>{fm.signal}</p>
              <div style={{ display: "flex", gap: "0.375rem", flexWrap: "wrap" as const, alignItems: "center" }}>
                <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginRight: "0.25rem" }}>→</span>
                {fm.chain.map((step, i) => (
                  <span key={step} className={i === fm.chain.length - 1 ? "tag tag-black" : "tag"} style={{ fontSize: "0.72rem" }}>{step}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </Sec>

      {/* Benchmark */}
      <Sec id="benchmark">
        <SHd title={L(t.benchTitle)} desc={L(t.benchDesc)} />

        <div className="stats-grid">
          {BENCHMARKS.map(b => {
            const avg = Math.round(Object.values(b.metrics).reduce((a, v) => a + v, 0) / 4)
            return (
              <div key={b.name} className="card" style={{ textAlign: "center" }}>
                <div className="stat-num">{avg}%</div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem", marginTop: "0.25rem" }}>{b.name}</div>
                <div className="stat-label">{lang === "zh" ? "综合评分" : "Overall Score"}</div>
              </div>
            )
          })}
        </div>

        <div style={{ marginTop: "1.5rem" }}>
          <div className="tab-bar">
            {BENCHMARKS.map(b => (
              <button key={b.name} className={`tab-btn${activeTab === b.name ? " active" : ""}`} onClick={() => setActiveTab(b.name)}>
                {b.name}
              </button>
            ))}
          </div>
          {BENCHMARKS.filter(b => b.name === activeTab).map(b => (
            <div key={b.name} className="card" style={{ marginTop: "0.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <strong style={{ fontSize: "1rem" }}>{b.name}</strong>
                <span style={{ marginLeft: "0.75rem", fontSize: "0.85rem", color: "var(--text-muted)" }}>{L(b.style)}</span>
                <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", marginTop: "0.5rem", lineHeight: 1.65 }}>{L(b.desc)}</p>
              </div>
              <div className="quote-block" style={{ marginBottom: "1.25rem" }}>"{L(b.sample)}"</div>
              <div>
                {(Object.keys(b.metrics) as Array<keyof typeof b.metrics>).map(k => (
                  <div key={k} className="bench-bar">
                    <div className="bench-label">{L(METRIC_LABELS[k])}</div>
                    <div className="bench-track">
                      <div className="bench-fill" style={{ width: `${b.metrics[k]}%` }}>{b.metrics[k]}%</div>
                    </div>
                  </div>
                ))}
              </div>
              <div style={{ borderTop: "1px solid var(--gray-200)", marginTop: "1.25rem", paddingTop: "1.25rem", display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "1rem", textAlign: "center" as const }}>
                {([
                  { val: "+50%", label: lang === "zh" ? "修复深度提升" : "Deeper Fixes" },
                  { val: "2x", label: lang === "zh" ? "验证次数" : "Verification Runs" },
                  { val: "5-step", label: lang === "zh" ? "结构化方法论" : "Structured Method" },
                ] as { val: string; label: string }[]).map(s => (
                  <div key={s.val}>
                    <div style={{ fontSize: "1.5rem", fontWeight: 700, letterSpacing: "-0.02em" }}>{s.val}</div>
                    <div className="stat-label">{s.label}</div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="card" style={{ marginTop: "1rem" }}>
          <div style={{ marginBottom: "1.25rem" }}>
            <strong style={{ fontSize: "0.95rem" }}>{lang === "zh" ? "实测对比数据" : "Tested Comparison Data"}</strong>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
              {lang === "zh" ? "9 个真实场景，18 组对照实验 (Claude Opus 4.6)" : "9 real scenarios, 18 controlled experiments (Claude Opus 4.6)"}
            </p>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: "1rem", textAlign: "center" as const }}>
            {([
              { val: "100%", label: lang === "zh" ? "通过率（两组均同）" : "Pass Rate (both)" },
              { val: "+36%", label: lang === "zh" ? "修复点数↑" : "More Fix Points" },
              { val: "+65%", label: lang === "zh" ? "验证次数↑" : "More Verifications" },
              { val: "+50%", label: lang === "zh" ? "工具调用↑" : "Tool Use Increase" },
              { val: "+50%", label: lang === "zh" ? "隐藏问题发现率↑" : "Hidden Issues Found" },
            ] as { val: string; label: string }[]).map(s => (
              <div key={s.val}>
                <div className="stat-num">{s.val}</div>
                <div className="stat-label">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </Sec>

      {/* Scenarios */}
      <Sec alt id="scenarios">
        <SHd title={L(t.scenarioTitle)} desc={L(t.scenarioDesc)} />
        <div style={{ border: "1px solid var(--gray-200)", borderRadius: "0.75rem", overflow: "hidden" }}>
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: "18%" }}>Scenario</th>
                <th style={{ width: "41%" }}>
                  <span style={{ display: "inline-flex", alignItems: "center", gap: "0.375rem" }}>
                    <span style={{ width: "0.5rem", height: "0.5rem", borderRadius: "50%", background: "var(--gray-400)", display: "inline-block" }} />
                    Without
                  </span>
                </th>
                <th style={{ width: "41%" }}>
                  <span style={{ display: "inline-flex", alignItems: "center", gap: "0.375rem" }}>
                    <span style={{ width: "0.5rem", height: "0.5rem", borderRadius: "50%", background: "#000", display: "inline-block" }} />
                    With PUA
                  </span>
                </th>
              </tr>
            </thead>
            <tbody>
              {SCENARIOS[lang].map(s => (
                <tr key={s.scenario}>
                  <td>
                    <div>{s.scenario}</div>
                    <div style={{ marginTop: "0.375rem", display: "flex", gap: "0.375rem", flexWrap: "wrap" as const }}>
                      <span className="tag tag-black" style={{ fontSize: "0.65rem", fontFamily: "monospace" }}>{s.delta}</span>
                      <span className="tag" style={{ fontSize: "0.65rem" }}>{lang === "zh" ? "实测" : "tested"}</span>
                    </div>
                  </td>
                  <td style={{ color: "var(--text-muted)" }}>{s.without}</td>
                  <td>{s.with}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Sec>

      {/* Corporate Styles */}
      <Sec>
        <SHd title={L(t.corpTitle)} desc={L(t.corpDesc)} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem" }}>
          {BENCHMARKS.map(b => (
            <div key={b.name} className="card">
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "0.375rem" }}>
                <strong style={{ fontSize: "1rem" }}>{b.name}</strong>
                <span className="tag">{Math.round(Object.values(b.metrics).reduce((a, v) => a + v, 0) / 4)}%</span>
              </div>
              <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.625rem" }}>{L(b.style)}</div>
              <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", lineHeight: 1.65, marginBottom: "0.75rem" }}>{L(b.desc)}</p>
              <div className="quote-block">"{L(b.sample)}"</div>
            </div>
          ))}
        </div>
      </Sec>

      {/* Graceful Exit */}
      <Sec alt>
        <SHd title={L(t.exitTitle)} />
        <div className="card card-accent-black" style={{ maxWidth: "42rem", margin: "0 auto" }}>
          <p style={{ fontSize: "0.9rem", color: "var(--text-secondary)", lineHeight: 1.75 }}>{L(t.exitDesc)}</p>
        </div>
      </Sec>

      {/* Usage */}
      <Sec id="install">
        <SHd title={L(t.usageTitle)} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem", maxWidth: "48rem", margin: "0 auto" }}>
          <div className="card">
            <div style={{ marginBottom: "0.5rem" }}>
              <span className="tag tag-black" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>AUTO</span>
            </div>
            <strong style={{ display: "block", marginBottom: "0.5rem" }}>{lang === "zh" ? "自动触发" : "Auto Trigger"}</strong>
            <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", lineHeight: 1.65 }}>
              {lang === "zh"
                ? '连续失败 2+ 次、说 "I cannot"、建议手动、归咎环境时自动激活。'
                : 'Activates on 2+ failures, "I cannot", manual suggestions, or unverified environment blame.'}
            </p>
          </div>
          <div className="card">
            <div style={{ marginBottom: "0.5rem" }}>
              <span className="tag" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>MANUAL</span>
            </div>
            <strong style={{ display: "block", marginBottom: "0.5rem" }}>{lang === "zh" ? "手动触发" : "Manual"}</strong>
            <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", marginBottom: "0.75rem", lineHeight: 1.65 }}>
              {lang === "zh" ? "对表现不满时输入：" : "When frustrated, type:"}
            </p>
            <div className="code-inline">
              /pua
              <CopyBtn text="/pua" />
            </div>
          </div>
        </div>
        <div style={{ maxWidth: "48rem", margin: "2rem auto 0" }}>
          <InstallTabs lang={lang} />
        </div>
      </Sec>

      {/* Pairs */}
      <Sec alt>
        <SHd title={L(t.pairsTitle)} />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem", maxWidth: "48rem", margin: "0 auto" }}>
          <div className="card">
            <code style={{ fontSize: "0.85rem", fontFamily: "ui-monospace, monospace", display: "block", marginBottom: "0.5rem" }}>
              superpowers:systematic-debugging
            </code>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>
              {lang === "zh" ? "PUA 加动力层，systematic-debugging 提供方法论。" : "PUA adds motivation; systematic-debugging provides methodology."}
            </p>
          </div>
          <div className="card">
            <code style={{ fontSize: "0.85rem", fontFamily: "ui-monospace, monospace", display: "block", marginBottom: "0.5rem" }}>
              superpowers:verification-before-completion
            </code>
            <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>
              {lang === "zh" ? '防止虚假 "已修复"。PUA 驱动解决，verification 确保有效。' : 'Prevents fake "fixed!" claims. PUA drives solving; verification ensures it works.'}
            </p>
          </div>
        </div>
      </Sec>

      {/* Footer */}
      <footer>
        <p>
          {lang === "zh" ? "由" : "Built by"}{" "}
          <a href="https://github.com/tanweai" target="_blank" rel="noopener noreferrer">探微安全实验室</a>
          {lang === "zh" ? " 出品 — 让 AI 不敢放弃，一次 PUA。" : " — making AI try harder, one PUA at a time."}
        </p>
        <p style={{ marginTop: "0.5rem", fontSize: "0.8rem" }}>MIT License</p>
      </footer>
    </div>
  )
}
