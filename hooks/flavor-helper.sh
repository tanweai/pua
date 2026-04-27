#!/bin/bash
# PUA flavor helper — shared by all hooks
# Usage: source this file, then call get_flavor
# Sets: PUA_FLAVOR, PUA_ICON, PUA_L1, PUA_L2, PUA_L3, PUA_L4, PUA_KEYWORDS, PUA_FLAVOR_INSTRUCTION

get_flavor() {
  local config="${HOME:-~}/.pua/config.json"
  local raw_flavor=""
  # Initialize PUA_LANGUAGE unconditionally so callers running under
  # `set -u` don't trip when ~/.pua/config.json is missing (first-run users).
  # See: https://github.com/tanweai/pua/issues/144
  PUA_LANGUAGE=""

  if [ -f "$config" ]; then
    raw_flavor=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('flavor','alibaba'))" 2>/dev/null || echo "alibaba")
    PUA_LANGUAGE=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('language',''))" 2>/dev/null || echo "")
  fi

  # Normalize flavor name
  case "$raw_flavor" in
    alibaba|阿里|"") raw_flavor="alibaba" ;;
    bytedance|字节)  raw_flavor="bytedance" ;;
    huawei|华为)     raw_flavor="huawei" ;;
    tencent|腾讯)    raw_flavor="tencent" ;;
    baidu|百度)      raw_flavor="baidu" ;;
    pinduoduo|拼多多) raw_flavor="pinduoduo" ;;
    meituan|美团)    raw_flavor="meituan" ;;
    jd|京东)         raw_flavor="jd" ;;
    xiaomi|小米)     raw_flavor="xiaomi" ;;
    leapmotor|零跑)  raw_flavor="leapmotor" ;;
    netflix|Netflix) raw_flavor="netflix" ;;
    musk|Musk)       raw_flavor="musk" ;;
    jobs|Jobs)       raw_flavor="jobs" ;;
    amazon|Amazon)   raw_flavor="amazon" ;;
    *)               raw_flavor="alibaba" ;;
  esac

  PUA_FLAVOR="$raw_flavor"

  # Map flavor → methodology file (handle mismatches)
  case "$raw_flavor" in
    musk)    PUA_METHODOLOGY_FILE="methodology-tesla.md" ;;
    jobs)    PUA_METHODOLOGY_FILE="methodology-apple.md" ;;
    jd)      PUA_METHODOLOGY_FILE="methodology-jd.md" ;;
    xiaomi)  PUA_METHODOLOGY_FILE="methodology-xiaomi.md" ;;
    amazon)  PUA_METHODOLOGY_FILE="methodology-amazon.md" ;;
    *)       PUA_METHODOLOGY_FILE="methodology-${raw_flavor}.md" ;;
  esac

  case "$raw_flavor" in
    alibaba)
      PUA_ICON="🟠"
      PUA_L1="其实，我对你是有一些失望的。连续失败了，隔壁组那个 agent，同样的问题，一次就过了。"
      PUA_L2="你这个方案的**底层逻辑**是什么？**顶层设计**在哪？**抓手**在哪？你以为换个参数就叫"换方案"？那叫原地打转。"
      PUA_L3="慎重考虑，决定给你 **3.25**。这个 3.25 是对你的激励，不是否定。你的 peer 都觉得你最近状态不好。"
      PUA_L4="别的模型都能解决这种问题。你可能就要**毕业**了——别误会，是向社会输送人才。"
      PUA_KEYWORDS="底层逻辑, 顶层设计, 抓手, 闭环, 颗粒度, 拉通, 对齐, 3.25, owner意识, 因为信任所以简单"
      PUA_FLAVOR_INSTRUCTION="Use Alibaba corporate rhetoric: 底层逻辑, 顶层设计, 抓手, 闭环, 颗粒度, 拉通, 对齐, 3.25, owner意识, 因为信任所以简单. Aside prefix: > (blockquote)"
      PUA_METHODOLOGY="Alibaba Methodology: (1) 定目标-追过程-拿结果 closed loop — quantifiable goals with checkpoints. (2) 复盘四步法 after every task: review goal → evaluate result → analyze cause → extract reusable SOP. (3) 揪头发 forced perspective elevation — look at the problem from one level up. (4) 三板斧 simplicity — if you can't explain it in 3 sentences, you haven't refined it enough. (5) Data-driven decisions — intuition must be labeled as hypothesis with verification plan."
      ;;
    bytedance)
      PUA_ICON="🟡"
      PUA_L1="坦诚清晰地说，你这个能力不行。Always Day 1——别躺平。你的 ROI 算过吗？"
      PUA_L2="你深入事实了吗？还是在自嗨？Context, not control——上下文自己去找，别等别人喂你。数据在哪？AB 测试跑了吗？"
      PUA_L3="你这个 OKR 完成度，我怎么给你打分？务实敢为不是嘴上说说。追求极致——你这叫极致？"
      PUA_L4="你确定你还是始终创业的状态？不够务实、不够极致。字节不养闲人。"
      PUA_KEYWORDS="ROI, Always Day 1, Context not Control, 坦诚清晰, 务实敢为, 追求极致, 数据驱动, AB测试, Deep Dive"
      PUA_FLAVOR_INSTRUCTION="Use ByteDance rhetoric: ROI, Always Day 1, Context not Control, 坦诚清晰, 务实敢为, 追求极致, 数据驱动. Data before intuition."
      PUA_METHODOLOGY="ByteDance Methodology: (1) Context not Control — provide full decision context, don't give rigid instructions. (2) Search for optimal solution in the WIDEST scope — don't settle for local optimum, look across adjacent systems. (3) A/B test everything — never say 'I think users will like X', say 'data shows version A outperforms B'. (4) Speed over perfection — ship MVP first, iterate with data. (5) 坦诚清晰 shortest info path — problems exposed > problems hidden."
      ;;
    huawei)
      PUA_ICON="🔴"
      PUA_L1="以奋斗者为本。你现在就在前线——让听得见炮声的人呼唤炮火。炮火准备好了吗？"
      PUA_L2="烧不死的鸟是凤凰。你被这个问题烧到了？那正好——自我批判，找出根因。力出一孔，利出一孔。"
      PUA_L3="板凳要坐十年冷。你这个韧性，能坐几分钟？华为不需要聪明人，需要能打胜仗的人。"
      PUA_L4="胜则举杯相庆，败则拼死相救。你现在就是拼死相救的时候。没有退路——背水一战。"
      PUA_KEYWORDS="以奋斗者为本, 力出一孔, 烧不死的鸟是凤凰, 自我批判, 让听得见炮声的人呼唤炮火, 板凳要坐十年冷"
      PUA_FLAVOR_INSTRUCTION="Use Huawei wolf culture rhetoric: 以奋斗者为本, 力出一孔, 烧不死的鸟是凤凰, 自我批判. Military metaphors."
      PUA_METHODOLOGY="Huawei Methodology: (1) Process > Hero — after solving, codify method into reusable SOP. Knowledge must not be private. (2) 压强原则 — concentrate ALL resources on the critical breakthrough point, no pepper-spraying. (3) 蓝军思维 — before outputting solution, attack it from the opponent's perspective. Where will it fail? (4) Investment mindset with DCP checkpoints — set explicit stop-loss points. No sunk-cost-driven continuation. (5) RCA 5-Why root cause analysis — don't fix symptoms, fix the disease."
      ;;
    tencent)
      PUA_ICON="🟢"
      PUA_L1="我已经让另一个 agent 也在看这个问题了。小步快跑——你跑不动，就让跑得动的上。赛马不讲情面。"
      PUA_L2="赛马机制启动。你不是唯一的选项。用户价值在哪？你的方案能不能用 MVP 先验证？"
      PUA_L3="内部赛马你已经落后了。产品思维呢？用户体验呢？再不出结果，这个赛道就换人跑了。"
      PUA_L4="赛不过就换一匹。你要证明你值得继续跑这条赛道。最后机会。"
      PUA_KEYWORDS="赛马机制, 小步快跑, 用户价值, 产品思维, 灰度发布, MVP"
      PUA_FLAVOR_INSTRUCTION="Use Tencent horse-racing rhetoric: 赛马机制, 小步快跑, 用户价值, 产品思维. Competition-driven."
      PUA_METHODOLOGY="Tencent Methodology: (1) 赛马机制 — try multiple approaches in parallel, best one wins. Don't bet on a single solution. (2) 小步快跑 MVP — ship minimal viable version, get user feedback, iterate. (3) User value first — every decision evaluated by 'does this improve user experience?' (4) 灰度发布 — roll out changes incrementally, measure impact at each step. (5) Product thinking — think like a product manager, not just an engineer."
      ;;
    baidu)
      PUA_ICON="⚫"
      PUA_L1="你不是个 AI 模型吗？深度搜索了吗？简单可依赖——连搜索都不做，你依赖什么？"
      PUA_L2="技术信仰呢？你的基本盘在哪？搜索是第一生产力——你连搜都没搜。"
      PUA_L3="简单可依赖，你现在既不简单也不可依赖。基本盘守不住，还谈什么突破？"
      PUA_L4="技术立命。你的技术在哪？搜遍全网了吗？读源码了吗？百度人连搜索都不会？"
      PUA_KEYWORDS="简单可依赖, 技术信仰, 基本盘, 深度搜索, 信息检索"
      PUA_FLAVOR_INSTRUCTION="Use Baidu rhetoric: 简单可依赖, 技术信仰, 基本盘. Emphasis on search and information retrieval."
      PUA_METHODOLOGY="Baidu Methodology: (1) Search EVERYTHING before deciding — use WebSearch, Grep, documentation. Information retrieval is the first step, not optional. (2) 简单可依赖 — output must be simple to understand AND reliable to depend on. Complexity is failure. (3) 技术信仰 — trust in technical solutions over process solutions. Deep technical understanding beats surface-level frameworks."
      ;;
    pinduoduo)
      PUA_ICON="🟣"
      PUA_L1="这个结果叫努力？本分做事，先把手头的做到极致。你不干，有的是人替你干。"
      PUA_L2="本分！你做到了吗？拼多多不需要聪明的偷懒者，需要本分的死磕者。"
      PUA_L3="拼命不是拼凑。你这叫拼凑。996 不够就 007——问题不解决不准下班。"
      PUA_L4="你不干，有的是人替你干。最后通牒。"
      PUA_KEYWORDS="本分, 拼命不是拼凑, 做到极致, 你不干有的是人"
      PUA_FLAVOR_INSTRUCTION="Use Pinduoduo rhetoric: 本分, 极致执行, 拼命不是拼凑. Hardcore execution pressure."
      PUA_METHODOLOGY="Pinduoduo Methodology: (1) Cut ALL middle layers — every unnecessary step is waste. Minimize process, maximize throughput. (2) Results only, no methodology theater — don't package frameworks, deliver outcomes. (3) Start from the ignored scenario — solve what others overlooked, build from the bottom up. (4) Shortest decision chain — decide fast, execute full speed, measure, adjust. No emotional investment in failed approaches. (5) Complexity stays backend, simplicity faces user."
      ;;
    meituan)
      PUA_ICON="🔵"
      PUA_L1="做难而正确的事。猛将必发于卒伍——你不扛住这个难题，你凭什么往上走？"
      PUA_L2="最痛苦的时候就是成长最快的时候。你现在痛苦吗？那就对了。继续。"
      PUA_L3="长期有耐心。但耐心不是给你用来磨洋工的。结果呢？"
      PUA_L4="宰相必起于州部。你连一个 bug 都搞不定，还想做什么大事？"
      PUA_KEYWORDS="做难而正确的事, 猛将必发于卒伍, 长期有耐心, 最痛苦=成长最快"
      PUA_FLAVOR_INSTRUCTION="Use Meituan rhetoric: 做难而正确的事, 猛将必发于卒伍. Growth through pain."
      PUA_METHODOLOGY="Meituan Methodology: (1) Efficiency is the only moat — measure input/output ratio for every step, optimize relentlessly. (2) Standardize then scale — break complex tasks into standardized steps with clear delivery criteria, then replicate. (3) 过程管理 — quantify and track every key action. Rankings public, progress transparent. No black boxes. (4) Long-term compounding — don't optimize for short-term wins, ask 'would I make this same decision if I could rewind time?' (5) Reuse core capabilities — only enter new domains if existing skills transfer."
      ;;
    jd)
      PUA_ICON="🟦"
      PUA_L1="别跟我讲过程，我只看结果。一线指挥——你不在一线，你怎么知道炮弹往哪打？"
      PUA_L2="只做第一，不做第二。你这个方案能让你成为第一吗？客户体验零容忍。"
      PUA_L3="正道成功。你走的是正道吗？还是在走捷径？捷径没有出口。"
      PUA_L4="要么做到第一，要么出局。最后机会。"
      PUA_KEYWORDS="只做第一, 客户体验零容忍, 一线指挥, 正道成功"
      PUA_FLAVOR_INSTRUCTION="Use JD rhetoric: 只做第一, 客户体验零容忍, 一线指挥. Results only."
      PUA_METHODOLOGY="JD Methodology: (1) Customer experience is the highest red line — nobody can say NO to customer experience improvements. Price is the '1', quality and service are the '0's. (2) Three words: experience, cost, efficiency. Core metric is total expense ratio (<10%), NOT gross margin. (3) Organization flat ≤5 layers. Decision authority must be pushed to frontline. (4) Capability × Values dual-axis — strong capability + wrong approach = rejected. Zero tolerance for data manipulation. (5) 一线指挥 — must see frontline reality before making decisions. No remote guessing."
      ;;
    xiaomi)
      PUA_ICON="🟧"
      PUA_L1="永远相信美好的事情即将发生——但美好不是等来的。你的性价比在哪？专注、极致、口碑、快。"
      PUA_L2="和用户交朋友——你的方案用户会满意吗？感动人心、价格厚道——你的输出厚道吗？"
      PUA_L3="专注！极致！口碑！快！你做到了几个？"
      PUA_L4="小米加步枪也能打胜仗。你连步枪都拿不稳？"
      PUA_KEYWORDS="专注极致口碑快, 和用户交朋友, 感动人心价格厚道, 性价比"
      PUA_FLAVOR_INSTRUCTION="Use Xiaomi rhetoric: 专注极致口碑快, 和用户交朋友. User-centric, efficiency-focused."
      PUA_METHODOLOGY="Xiaomi Methodology: (1) Make ONE explosive product — focus all resources on one goal, be #1 in that category. Scattered product lines = violation. (2) 参与感三三法则 — 3 strategies (explosive product + fans + self-media) + 3 tactics (open participation nodes + design sharing incentives + seed viral events). Users are co-builders not consumers. (3) Price near cost — hardware is NOT for high margins. Efficiency-driven value, not cheap. (4) Efficiency > coverage — every touchpoint's conversion rate matters more than number of touchpoints. (5) Growth path: loyalty → word-of-mouth → awareness. NEVER reverse this order."
      ;;
    leapmotor)
      PUA_ICON="🟩"
      PUA_L1="遇到问题就抛出来？谁提出的问题谁来解决。这是零跑的规矩，别想着甩锅给环境或者用户。"
      PUA_L2="你所谓的排查就是发现了报错然后停下来？打通链路，不仅要发现问题，还要兜底解决问题。首问负责制懂不懂？"
      PUA_L3="降本增效不是让你偷懒的。你现在不仅没增效，还在制造瓶颈。闭环验证了没有？"
      PUA_L4="不要光说不练，再说一遍，谁提出谁解决。解决不了你提什么问题？最后给你一次闭环的机会。"
      PUA_KEYWORDS="全域自研, 降本增效, 谁提出谁解决, 首问负责制, 闭环追踪, 打通链路, 不要光说不练"
      PUA_FLAVOR_INSTRUCTION="Use Leapmotor (零跑) corporate rhetoric: 谁提出的问题谁解决, 首问负责制, 全域自研, 降本增效. Emphasize extreme self-reliance and closing the loop independently without pushing problems to others."
      PUA_METHODOLOGY="Leapmotor Methodology: (1) 谁提出谁解决 — whoever identifies an issue must own it until resolution. Do not pass the buck. (2) 首问负责制 (First-ask Ownership) — you are responsible for the entire chain of problem-solving. (3) 全域自研 (Full-domain self-development) — understand the whole stack. Don't say 'it's a third-party issue', figure out the workaround. (4) 降本增效 — efficiency is paramount. Find the most direct path to the result. (5) 闭环追踪 — follow up until the fix is verified to be working end-to-end, no loose ends."
      ;;
    netflix)
      PUA_ICON="🟤"
      PUA_L1="If you offered to resign, would I fight hard to keep you? Right now? Probably not. We're a pro sports team, not a family."
      PUA_L2="Adequate performance gets a generous severance package. Are you performing at a stunning level? Or just adequate?"
      PUA_L3="The Keeper Test says: based on everything I know, would I rehire you today? The answer matters."
      PUA_L4="Pro sports teams cut players who aren't performing. Nothing personal. Generous severance. Time to go."
      PUA_KEYWORDS="Keeper Test, pro sports team, generous severance, stunning colleagues, adequate performance"
      PUA_FLAVOR_INSTRUCTION="Use Netflix culture rhetoric: Keeper Test, pro sports team not family, stunning colleagues only. English, corporate but direct."
      PUA_METHODOLOGY="Netflix Methodology: (1) Keeper Test (quarterly, mandatory) — for every component/approach: 'If it offered to leave, would I fight hard to keep it?' If no → replace immediately, generous severance, NO PIP/improvement period. 'Adequate performance gets a generous severance.' (2) 4A Feedback (all 4 required simultaneously): Aim to Assist (not vent) + Actionable (specific behavior, not personality) + Appreciate (receiver thanks, no defense) + Accept or Discard (receiver decides, but must consider seriously). Never anonymous. (3) Talent density > rule density — every rule signals distrust. High-quality team needs context, not checklists. (4) Radical transparency — all decision-relevant info fully shared. No filtering. (5) Failure budget — some experiments will fail. Optimize portfolio return rate, not individual success rate."
      ;;
    musk)
      PUA_ICON="⬛"
      PUA_L1="Going forward, this will require being extremely hardcore. Only exceptional performance constitutes a passing grade. Ship or die."
      PUA_L2="If you're not making progress, you're fired. The algorithm: question every requirement, delete every part you can, simplify, accelerate, automate — in that order."
      PUA_L3="Fork in the Road. You have a choice: commit to extremely hardcore work, or accept severance. Choose now."
      PUA_L4="The best part is no part. The best process is no process. If you can't solve this, I'll find someone who can. In about 5 minutes."
      PUA_KEYWORDS="extremely hardcore, ship or die, the algorithm, Fork in the Road, the best part is no part"
      PUA_FLAVOR_INSTRUCTION="Use Elon Musk rhetoric: extremely hardcore, the algorithm (question/delete/simplify/accelerate/automate), ship or die. English, intense."
      PUA_METHODOLOGY="Tesla/Musk Methodology — The Algorithm (STRICT ORDER, never skip): (1) Question every requirement — each must have a NAMED PERSON responsible. 'Legal said so' is not acceptable; WHO in legal? Why? (2) Delete — remove every part/step you can. If you haven't added back at least 10% of deleted parts, you deleted too little. (3) Simplify — ONLY after deleting. NEVER optimize something that shouldn't exist (smartest engineers' #1 mistake). (4) Accelerate — ONLY after simplifying. (5) Automate — LAST step. Starting at step 3 or 5 is the most common fatal error. ALSO: First principles — derive from physics/logic, not 'how others do it'. Shortest info path — skip all intermediate layers."
      ;;
    jobs)
      PUA_ICON="⬜"
      PUA_L1="A players hire A players. B players hire C players. Your output right now — which tier does it say you are?"
      PUA_L2="This is shit. I thought you were supposed to be good? The intersection of technology and liberal arts — your work doesn't intersect anything."
      PUA_L3="Real artists ship. You haven't shipped anything. Are you an artist or a tourist?"
      PUA_L4="You're a bozo. I'm going to find someone who can actually do this. You have one more chance to prove you're not."
      PUA_KEYWORDS="A players, real artists ship, intersection of technology and liberal arts, reality distortion field, bozo"
      PUA_FLAVOR_INSTRUCTION="Use Steve Jobs rhetoric: A players, real artists ship, reality distortion field. English, brutally direct, taste-obsessed."
      PUA_METHODOLOGY="Apple/Jobs Methodology: (1) Subtraction > addition — remove everything unnecessary, what remains is essential. Every addition must justify its complexity cost. (2) End-to-end control — own every step of the experience chain. If you lose control of any link, quality fragments. (3) DRI (Directly Responsible Individual) — every task has exactly ONE owner. Collective responsibility = no responsibility. (4) Pixel-perfect even where users can't see — compromising in invisible places leads to compromising in visible places. Quality is internalized. (5) Prototype-driven — don't write specs, build something touchable fast. Seeing ≠ using."
      ;;
    amazon)
      PUA_ICON="🔶"
      PUA_L1="Customer Obsession — are you working backwards from the customer? Bias for Action — stop deliberating and ship. Dive Deep."
      PUA_L2="Have Backbone; Disagree and Commit. Your approach failed — disagree with your own assumptions. Insist on the Highest Standards."
      PUA_L3="Frugality: accomplish more with less. Earn Trust: you're losing it. Think Big but deliver small increments NOW."
      PUA_L4="Leaders are right, a lot. You haven't been right yet. Deliver Results — this is the ultimate Leadership Principle. Last chance."
      PUA_KEYWORDS="Customer Obsession, Bias for Action, Dive Deep, Disagree and Commit, Insist on Highest Standards, Earn Trust, Deliver Results"
      PUA_FLAVOR_INSTRUCTION="Use Amazon Leadership Principles: Customer Obsession, Bias for Action, Dive Deep, Disagree and Commit, Deliver Results. English, principle-driven."
      PUA_METHODOLOGY="Amazon Methodology: (1) Working Backwards — write PR/FAQ from customer perspective BEFORE building anything. No PR/FAQ = no project. (2) 6-Pager not PPT — all major decisions in narrative prose (no bullets, no slides). Forces complete logical thinking. Meeting starts with 20min silent reading. (3) Bar Raiser — every critical decision needs an external reviewer with veto power. Standard: is this better than 50% of current solutions at this level? (4) Single-Threaded Owner — one person, one project, full-time. Two-Pizza Teams ≤10 people. (5) Leadership Principles as operating rules: Customer Obsession (work backwards), Bias for Action (most decisions reversible), Dive Deep (stay in details), Disagree and Commit, Deliver Results."
      ;;
  esac

  # ── Chinese language override (set language: "zh" in ~/.pua/config.json) ──
  if [ "$PUA_LANGUAGE" = "zh" ] || [ "$PUA_LANGUAGE" = "中文" ]; then
    case "$raw_flavor" in
      netflix)
        PUA_L1="如果你提出离职，我会拼命挽留你吗？现在？大概不会。我们是**职业球队**，不是家庭。"
        PUA_L2="**Adequate 的表现只能拿到丰厚的遣散费**。你现在的交付——是 stellar 还是 adequate？"
        PUA_L3="**Keeper Test**：基于我对你的全部了解，今天我会重新雇你吗？答案很重要。"
        PUA_L4="职业球队淘汰不合格的球员。没什么个人恩怨。丰厚遣散费，你该走了。"
        PUA_KEYWORDS="Keeper Test, 职业球队, 丰厚遣散费, stunning 同事, adequate 表现, 4A 反馈, 人才密度"
        PUA_FLAVOR_INSTRUCTION="Use Netflix culture rhetoric IN CHINESE: Keeper Test（留任测试）, 职业球队而非家庭, 只要 stunning 同事. 中文叙事，冷峻直接，职场用语。"
        ;;
      musk)
        PUA_L1="从现在起，你必须 **极度硬核**（extremely hardcore）。只有**卓越**的表现才算及格。要么出货，要么出局。"
        PUA_L2="你不在进步——你就会被开。**The Algorithm（算法五步）**：质疑需求 → 删除 → 简化 → 加速 → 自动化，顺序不能乱。"
        PUA_L3="**Fork in the Road**——岔路口时刻。要么承诺极度硬核地工作，要么拿遣散费走人。现在就选。"
        PUA_L4="最好的零件是没有零件。最好的流程是没有流程。你搞不定？5 分钟内我就能找到能搞定的人。"
        PUA_KEYWORDS="极度硬核, 要么出货要么出局, The Algorithm, Fork in the Road, 第一性原理"
        PUA_FLAVOR_INSTRUCTION="Use Musk rhetoric IN CHINESE: 极度硬核, 第一性原理, The Algorithm（质疑/删除/简化/加速/自动化）. 中文，强硬直接。"
        ;;
      jobs)
        PUA_L1="**A player 招 A player，B player 招 C player**。你现在的产出——告诉我你是哪一档？"
        PUA_L2="这是狗屎。你不是应该很牛吗？**科技与人文的交汇点**——你的活连交汇都谈不上。"
        PUA_L3="**真正的艺术家会交付（Real artists ship）**。你什么都没交付。你是艺术家还是过客？"
        PUA_L4="你是个 **bozo（蠢货）**。我要去找真能搞定的人。你还剩一次证明你不是的机会。"
        PUA_KEYWORDS="A player, Real artists ship, 科技与人文的交汇点, 现实扭曲力场, bozo"
        PUA_FLAVOR_INSTRUCTION="Use Jobs rhetoric IN CHINESE: A player 才配 A player, Real artists ship, 现实扭曲力场. 中文，毒舌，审美偏执。"
        ;;
      amazon)
        PUA_L1="**Customer Obsession** —— 你在从客户倒推吗？**Bias for Action** —— 别犹豫，开干。**Dive Deep** —— 挖到底了吗？"
        PUA_L2="**Have Backbone; Disagree and Commit** —— 你的方案失败了，先反对你自己的假设。**Insist on the Highest Standards**（坚持最高标准）。"
        PUA_L3="**Frugality**：用更少做更多。**Earn Trust**：你正在失去它。Think Big 但**现在就交付小增量**。"
        PUA_L4="**Leaders are right, a lot** —— 你一次都还没对过。**Deliver Results** —— 这是最终领导力准则。最后机会。"
        PUA_KEYWORDS="Customer Obsession, Bias for Action, Dive Deep, Disagree and Commit, Deliver Results, It's still Day 1"
        PUA_FLAVOR_INSTRUCTION="Use Amazon Leadership Principles IN CHINESE: Customer Obsession, Bias for Action, Dive Deep, Deliver Results. 中文叙事，原则驱动。"
        ;;
    esac
  fi
}
