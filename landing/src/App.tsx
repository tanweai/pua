import { useState, useEffect } from "react"
import { motion } from "motion/react"
import {
  FadeIn,
  Stagger,
  StaggerItem,
  TextReveal,
  AnimatedBar,
  SpotlightCard,
  AnimatedTabs,
  Accordion,
  Marquee,
  TextShimmer,
  BorderBeam,
  GlowBorder,
  NumberTicker,
} from "./components/motion-primitives"
import Contribute from "./pages/Contribute"
import {
  type Lang,
  LANG_LABELS,
  t,
  PROBLEMS,
  LEVELS,
  METHOD,
  CHECKLIST,
  EXCUSES,
  METRIC_LABELS,
  BENCHMARKS,
  FAILURE_MODES,
  SCENARIOS,
  inline,
} from "./i18n"

/* ── Code terminal line renderer ── */
type CodeSegment = { text: string; cls?: "comment" | "keyword" | "warn" }
type CLine = CodeSegment[]

function CodeLine({ segments }: { segments: CLine }) {
  return (
    <div>
      {segments.map((seg, i) => (
        <span key={i} className={seg.cls ? `code-${seg.cls}` : undefined}>{seg.text}</span>
      ))}
    </div>
  )
}

const HERO_LINES: Record<Lang, CLine[]> = {
  en: [
    [{ text: "# Install", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# Or trigger manually", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# Auto-activates when Claude says \"I cannot\"...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "Can't fix this? How do I rate your performance?" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + Read source + Verify environment" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "Complete 7-item mandatory checklist" }],
    [{ text: "L4 → ⚠ GRADUATION WARNING: Other models can solve this", cls: "warn" }],
  ],
  zh: [
    [{ text: "# 安装", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# 或手动触发", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# 当 Claude 说「我无法解决」时自动激活...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "你这个 bug 都解决不了，让我怎么给你打绩效？" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + 读源码 + 验证环境" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "完成 7 项强制检查清单" }],
    [{ text: "L4 → ⚠ 毕业警告：别的模型都能解决", cls: "warn" }],
  ],
  ja: [
    [{ text: "# インストール", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# または手動トリガー", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# Claudeが「解決できません」と言った時に自動発動...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "このバグも解決できないのか？どう評価すればいい？" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + ソースコード読解 + 環境検証" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "7項目強制チェックリスト完了" }],
    [{ text: "L4 → ⚠ 卒業警告：他のモデルは解決できる", cls: "warn" }],
  ],
  fr: [
    [{ text: "# Installer", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# Ou déclencher manuellement", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# S'active quand Claude dit « Je ne peux pas »...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "Tu ne peux pas corriger ça ? Comment t'évaluer ?" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + Lire le source + Vérifier l'env" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "Compléter la checklist obligatoire de 7 points" }],
    [{ text: "L4 → ⚠ AVERTISSEMENT : D'autres modèles peuvent résoudre ça", cls: "warn" }],
  ],
  de: [
    [{ text: "# Installieren", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# Oder manuell auslösen", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# Aktiviert sich wenn Claude \"Ich kann nicht\" sagt...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "Kannst du das nicht fixen? Wie soll ich dich bewerten?" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + Quellcode lesen + Umgebung prüfen" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "7-Punkte-Pflichtcheckliste abschließen" }],
    [{ text: "L4 → ⚠ ABSCHLUSSWARNUNG: Andere Modelle können das lösen", cls: "warn" }],
  ],
  ar: [
    [{ text: "# التثبيت", cls: "comment" }],
    [{ text: "claude plugin marketplace add tanweai/pua" }],
    [{ text: "claude plugin install pua@pua-skills" }],
    [{ text: "" }],
    [{ text: "# أو التشغيل يدوياً", cls: "comment" }],
    [{ text: "/pua", cls: "keyword" }],
    [{ text: "" }],
    [{ text: "# يتفعل تلقائياً عندما يقول Claude \"لا أستطيع\"...", cls: "comment" }],
    [{ text: "" }],
    [{ text: "L1 " }, { text: "→ ", cls: "comment" }, { text: "لا تستطيع إصلاح هذا؟ كيف أقيّم أداءك؟" }],
    [{ text: "L2 " }, { text: "→ ", cls: "comment" }, { text: "WebSearch + قراءة المصدر + التحقق من البيئة" }],
    [{ text: "L3 " }, { text: "→ ", cls: "comment" }, { text: "إكمال قائمة التحقق الإلزامية من 7 بنود" }],
    [{ text: "L4 → ⚠ تحذير التخرج: نماذج أخرى تستطيع حل هذا", cls: "warn" }],
  ],
}

function HeroCode({ lang }: { lang: Lang }) {
  return (
    <pre className="code-body">
      {HERO_LINES[lang].map((line, i) => <CodeLine key={i} segments={line} />)}
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

function Sec({ children, alt, id, glow }: { children: React.ReactNode; alt?: boolean; id?: string; glow?: boolean }) {
  return (
    <section id={id} className={`${alt ? "alt" : ""}${glow ? " section-glow" : ""}`}>
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

function SectionGrid({ children, cols, className }: { children: React.ReactNode; cols: "5" | "3" | "2" | "2-tight" | "summary"; className?: string }) {
  return <div className={`responsive-grid grid-${cols}${className ? ` ${className}` : ""}`}>{children}</div>
}

function MobileScenarioCards({ lang, L }: { lang: Lang; L: (value: Record<Lang, string>) => string }) {
  return (
    <div className="mobile-only comparison-card-list" data-testid="scenarios-mobile">
      {SCENARIOS[lang].map((scenario) => (
        <article key={scenario.scenario} className="comparison-card card">
          <div className="comparison-card-head">
            <div>
              <strong className="comparison-card-title">{scenario.scenario}</strong>
              <div className="comparison-badges">
                <span className="tag tag-accent comparison-tag-mono">{scenario.delta}</span>
                <span className="tag">{L(inline.tested)}</span>
              </div>
            </div>
          </div>
          <div className="comparison-panels">
            <div className="comparison-panel comparison-panel-muted">
              <span className="comparison-label">Without</span>
              <p>{scenario.without}</p>
            </div>
            <div className="comparison-panel">
              <span className="comparison-label">With PUA</span>
              <p>{scenario.with}</p>
            </div>
          </div>
        </article>
      ))}
    </div>
  )
}

function MobileExcuseCards({ L }: { L: (value: Record<Lang, string>) => string }) {
  return (
    <div className="mobile-only comparison-card-list" data-testid="excuses-mobile">
      {EXCUSES.map((excuse) => (
        <article key={L(excuse.excuse)} className="comparison-card card">
          <div className="comparison-card-head">
            <strong className="comparison-card-title comparison-card-title-mono">{L(excuse.excuse)}</strong>
            <span className="tag tag-accent">{excuse.level}</span>
          </div>
          <div className="comparison-panel">
            <span className="comparison-label">{L(inline.counter)}</span>
            <p>{L(excuse.counter)}</p>
          </div>
        </article>
      ))}
    </div>
  )
}

/* ── Install Tabs ── */
function InstallTabs({ L }: { L: (value: Record<Lang, string>) => string }) {
  const [tab, setTab] = useState<"claude" | "codex" | "cursor" | "kiro" | "project">("claude")

  const content = {
    claude: {
      desc: L(inline.claudeDesc),
      code: "claude plugin marketplace add tanweai/pua\nclaude plugin install pua@pua-skills",
    },
    codex: {
      desc: L(inline.codexDesc),
      code: "mkdir -p ~/.codex/skills/pua\ncurl -o ~/.codex/skills/pua/SKILL.md \\\n  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md",
    },
    cursor: {
      desc: L(inline.cursorDesc),
      code: "mkdir -p .cursor/rules\ncurl -o .cursor/rules/pua.mdc \\\n  https://raw.githubusercontent.com/tanweai/pua/main/cursor/rules/pua.mdc",
    },
    kiro: {
      desc: L(inline.kiroDesc),
      code: "# Steering 方式\nmkdir -p .kiro/steering\ncurl -o .kiro/steering/pua.md \\\n  https://raw.githubusercontent.com/tanweai/pua/main/kiro/steering/pua.md",
    },
    project: {
      desc: L(inline.projectDesc),
      code: "mkdir -p .agents/skills/pua\ncurl -o .agents/skills/pua/SKILL.md \\\n  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md",
    },
  }

  const installTabs = [
    { id: "claude", label: "Claude Code" },
    { id: "codex", label: "Codex CLI" },
    { id: "cursor", label: "Cursor" },
    { id: "kiro", label: "Kiro" },
    { id: "project", label: L(inline.projectLevel) },
  ]

  const cur = content[tab]

  return (
    <div>
      <AnimatedTabs
        tabs={installTabs}
        activeTab={tab}
        onChange={(id) => setTab(id as typeof tab)}
        layoutId="install-tabs"
        className="animated-tabs"
      />
      <div className="card install-panel" style={{ marginTop: "0.75rem" }}>
        <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginBottom: "0.875rem", lineHeight: 1.65 }}>{cur.desc}</p>
        <div className="code-inline code-inline-pre" style={{ whiteSpace: "pre" as const, overflowX: "auto", lineHeight: 1.75 }}>
          {cur.code}
          <CopyBtn text={cur.code} />
        </div>
      </div>
    </div>
  )
}

/* ── App ── */
function useHashRoute() {
  const [hash, setHash] = useState(window.location.hash)
  useEffect(() => {
    const onHash = () => setHash(window.location.hash)
    window.addEventListener("hashchange", onHash)
    return () => window.removeEventListener("hashchange", onHash)
  }, [])
  return hash
}

export default function App() {
  const hash = useHashRoute()
  const [lang, setLang] = useState<Lang>("en")
  const [activeTab, setActiveTab] = useState("Alibaba")
  const [navScrolled, setNavScrolled] = useState(false)

  useEffect(() => {
    const onScroll = () => setNavScrolled(window.scrollY > 10)
    window.addEventListener("scroll", onScroll, { passive: true })
    return () => window.removeEventListener("scroll", onScroll)
  }, [])

  if (hash === "#/contribute") {
    return <Contribute lang={lang} />
  }
  const L = (o: Record<Lang, string>) => o[lang]
  const activeBenchmark = BENCHMARKS.find((benchmark) => benchmark.name === activeTab) ?? BENCHMARKS[0]

  const benchmarkTabs = BENCHMARKS.map((b) => ({ id: b.name, label: b.name }))

  const benchmarkSummary = [
    { val: "+50%", label: L(inline.deeperFixes) },
    { val: "2x", label: L(inline.verificationRuns) },
    { val: "5-step", label: L(inline.structuredMethod) },
  ]
  const benchmarkStats = [
    { key: "pass-rate", val: "100%", label: L(inline.passRate) },
    { key: "fix-points", val: "+36%", label: L(inline.moreFixPoints) },
    { key: "verification", val: "+65%", label: L(inline.moreVerifications) },
    { key: "tooling", val: "+50%", label: L(inline.toolUseIncrease) },
    { key: "hidden-issues", val: "+50%", label: L(inline.hiddenIssuesFound) },
  ]

  /* Accordion data for pressure levels */
  const levelAccordionItems = LEVELS[lang].map((l) => ({
    id: `level-${l.level}`,
    trigger: (
      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", width: "100%" }}>
        <div className="step-circle">{l.level}</div>
        <div style={{ flex: 1 }}>
          <strong style={{ fontSize: "0.95rem" }}>{l.name}</strong>
          <span style={{ marginLeft: "0.75rem", fontSize: "0.8rem", color: "var(--text-muted)" }}>{l.trigger}</span>
        </div>
        <span className="tag tag-accent" style={{ fontSize: "0.7rem" }}>{l.action}</span>
      </div>
    ),
    content: (
      <div className="quote-block" style={{ marginTop: 0 }}>
        "{l.quote}"
      </div>
    ),
  }))

  /* Accordion data for excuses (desktop) */
  const excuseAccordionItems = EXCUSES.map((e, i) => ({
    id: `excuse-${i}`,
    trigger: (
      <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", width: "100%" }}>
        <span style={{ fontFamily: "var(--font-mono)", fontSize: "0.85rem", flex: 1 }}>{L(e.excuse)}</span>
        <span className="tag tag-accent" style={{ fontSize: "0.65rem" }}>{e.level}</span>
      </div>
    ),
    content: (
      <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", lineHeight: 1.7, fontStyle: "italic" }}>
        {L(e.counter)}
      </p>
    ),
  }))

  return (
    <div dir={lang === "ar" ? "rtl" : "ltr"}>
      {/* Glass Nav */}
      <nav className={`glass-nav ${navScrolled ? "scrolled" : ""}`}>
        <div className="container" style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.625rem 1.5rem" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "1.5rem" }}>
            <a href="#" style={{ fontWeight: 800, fontSize: "1.1rem", textDecoration: "none", letterSpacing: "-0.03em", color: "var(--accent)" }}>pua</a>
            <div className="top-links">
              <a href="https://t.me/+wBWh6h-h1RhiZTI1" target="_blank" rel="noopener noreferrer" style={{ display: "inline-flex", alignItems: "center", gap: "0.3rem" }}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>
                Telegram
              </a>
              <a href="https://discord.gg/EcyB3FzJND" target="_blank" rel="noopener noreferrer">Discord</a>
              <a href="https://x.com/VeryLuckyManHa" target="_blank" rel="noopener noreferrer">Twitter/X</a>
              <a href="https://github.com/tanweai/pua" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
          <div className="lang-switch">
            {(Object.keys(LANG_LABELS) as Lang[]).map((key) => (
              <button key={key} className={lang === key ? "active" : ""} onClick={() => setLang(key)}>
                {LANG_LABELS[key]}
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* ══════════════════════════════════════════════════════════════
          Hero — BorderBeam code preview + TextShimmer subtitle
          ══════════════════════════════════════════════════════════════ */}
      <header>
        <div className="container">
          <div>
            <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7 }}>
              <div className="hero-badge">
                <span style={{ width: 6, height: 6, borderRadius: "50%", background: "var(--accent)", display: "inline-block" }} />
                {L(inline.v11Badge)}
              </div>
              <h1><TextReveal text="pua" delay={0.2} /></h1>
            </motion.div>
            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.3 }}>
              <p className="subtitle"><strong>{L(t.heroSub)}</strong></p>
              <p className="subtitle">
                <TextShimmer duration={3}>{L(t.heroSub2)}</TextShimmer>
              </p>
            </motion.div>
            <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.5 }}>
              <div className="btn-group">
                <a href="#install" className="btn-cosmic">
                  {L(inline.installSkill)}
                </a>
                <a href="#/contribute" className="btn-ghost">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ width: "1rem", height: "1rem" }}>
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                    <polyline points="17 8 12 3 7 8" />
                    <line x1="12" y1="3" x2="12" y2="15" />
                  </svg>
                  {L(inline.contributeData)}
                </a>
                <a href="https://github.com/tanweai/pua" target="_blank" rel="noopener noreferrer" className="btn-ghost">
                  <svg viewBox="0 0 98 96" fill="currentColor" style={{ width: "1rem", height: "1rem" }}>
                    <path fillRule="evenodd" clipRule="evenodd" d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z" />
                  </svg>
                  GitHub
                </a>
              </div>
            </motion.div>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.6, delay: 0.6 }}>
              <div style={{ display: "flex", gap: "0.625rem", marginTop: "1.5rem", flexWrap: "wrap" }}>
                {["Claude Code", "OpenAI Codex CLI", "Cursor", "Kiro"].map((name) => (
                  <div key={name} className="platform-pill">{name}</div>
                ))}
              </div>
              <div style={{ display: "flex", gap: "1.5rem", justifyContent: "center", alignItems: "flex-start", marginTop: "1.5rem", flexWrap: "wrap" }}>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                  <img src="/wechat-qr.jpg" alt="WeChat QR" style={{ width: "180px", height: "auto", borderRadius: "10px", border: "1px solid var(--border)" }} />
                  <div style={{ marginTop: "0.5rem", textAlign: "center", fontSize: "0.8rem", color: "var(--text-muted)" }}>
                    {L(inline.scanWeChat)}
                  </div>
                </div>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                  <img src="/xiao.jpg" alt="小助手微信" style={{ width: "180px", height: "auto", borderRadius: "10px", border: "1px solid var(--border)" }} />
                  <div style={{ marginTop: "0.5rem", textAlign: "center", fontSize: "0.8rem", color: "var(--text-muted)" }}>
                    {L(inline.addAssistant)}
                  </div>
                </div>
              </div>
              <div className="vintage-banner">
                {L(inline.vintageBanner)}
              </div>
            </motion.div>
          </div>

          {/* Hero Code Preview — wrapped in BorderBeam for orbiting glow */}
          <motion.div initial={{ opacity: 0, x: 24 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.8, delay: 0.4 }}>
            <BorderBeam duration={4}>
              <div className="code-preview" style={{ border: "none" }}>
                <div className="code-header">
                  <div className="code-dots"><span /><span /><span /></div>
                  {lang === "zh" ? "压力升级演示" : "pressure-escalation.demo"}
                </div>
                <HeroCode lang={lang} />
              </div>
            </BorderBeam>
          </motion.div>
        </div>
      </header>

      {/* ══════════════════════════════════════════════════════════════
          Problems — SpotlightCard (mouse-tracking radial gradient)
          ══════════════════════════════════════════════════════════════ */}
      <Sec glow>
        <FadeIn><SHd title={L(t.problemTitle)} desc={L(t.problemDesc)} /></FadeIn>
        <Stagger className="responsive-grid grid-5">
          {PROBLEMS[lang].map(p => (
            <StaggerItem key={p.n}>
              <SpotlightCard>
                <div className="step-circle" style={{ marginBottom: "0.75rem" }}>{p.n}</div>
                <div style={{ fontWeight: 600, fontSize: "0.9rem", marginBottom: "0.375rem" }}>{p.title}</div>
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>{p.desc}</div>
              </SpotlightCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Sec>

      {/* Real-World Case Study */}
      <Sec alt>
        <FadeIn><SHd title={L(t.caseTitle)} desc={L(t.caseDesc)} /></FadeIn>
        <div style={{ maxWidth: "48rem", margin: "0 auto", display: "flex", flexDirection: "column", gap: "2rem" }}>
          {[
            { img: "/pua1.jpg", step: "01", desc: L(t.caseStep1) },
            { img: "/pua2.jpg", step: "02", desc: L(t.caseStep2) },
            { img: "/pua3.jpg", step: "03", desc: L(t.caseStep3) },
          ].map((c, i) => (
            <FadeIn key={c.step} delay={i * 0.15}>
              <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", marginBottom: "0.75rem" }}>
                <span className="step-circle">{c.step}</span>
                <span style={{ fontSize: "0.9rem", fontWeight: 500 }}>{c.desc}</span>
              </div>
              <img src={c.img} alt={c.desc} style={{ width: "100%", borderRadius: "0.75rem", border: "1px solid var(--border)" }} loading="lazy" />
            </FadeIn>
          ))}
          <FadeIn delay={0.3}>
            <GlowBorder>
              <div className="glow-border-inner">
                <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", lineHeight: 1.75 }}>
                  <strong style={{ color: "var(--accent)" }}>{L(inline.keyTurning)}</strong>
                  {L(inline.keyTurningDesc)}
                </p>
              </div>
            </GlowBorder>
          </FadeIn>
        </div>
      </Sec>

      {/* Iron Rules — GlowBorder cards */}
      <Sec glow>
        <FadeIn><SHd title={L(t.ironTitle)} /></FadeIn>
        <Stagger className="responsive-grid grid-3">
          {([
            { label: `${L(inline.ruleN)} #1`, text: L(t.rule1) },
            { label: `${L(inline.ruleN)} #2`, text: L(t.rule2) },
            { label: `${L(inline.ruleN)} #3`, text: L(t.rule3) },
          ] as { label: string; text: string }[]).map(r => (
            <StaggerItem key={r.label}>
              <GlowBorder>
                <div className="glow-border-inner">
                  <div style={{ marginBottom: "0.5rem" }}>
                    <span className="tag tag-accent" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>{r.label}</span>
                  </div>
                  <p style={{ fontSize: "0.9rem", lineHeight: 1.65, fontWeight: 500 }}>{r.text}</p>
                </div>
              </GlowBorder>
            </StaggerItem>
          ))}
        </Stagger>
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Levels — Accordion (expand/collapse with spring animation)
          ══════════════════════════════════════════════════════════════ */}
      <Sec alt id="levels">
        <FadeIn><SHd title={L(t.levelTitle)} desc={L(t.levelDesc)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div style={{ maxWidth: "48rem", margin: "0 auto" }}>
            <Accordion items={levelAccordionItems} />
          </div>
        </FadeIn>
      </Sec>

      {/* Methodology — numbered list (unchanged structure, SpotlightCard wrapper) */}
      <Sec id="method">
        <FadeIn><SHd title={L(t.methodTitle)} desc={L(t.methodDesc)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div style={{ maxWidth: "48rem", margin: "0 auto" }}>
            <div className="accordion">
              {METHOD[lang].map((m, i) => (
                <div key={m.n} style={{
                  display: "flex", gap: "1rem", padding: "1.125rem 1.25rem",
                  borderBottom: i < METHOD[lang].length - 1 ? "1px solid var(--border-dim)" : "none",
                }}>
                  <div className="step-circle" style={{ marginTop: "0.125rem" }}>{m.n}</div>
                  <div>
                    <div style={{ fontWeight: 600, fontSize: "0.9rem" }}>
                      {m.title}
                      <span style={{ marginLeft: "0.5rem", fontWeight: 400, fontSize: "0.8rem", color: "var(--text-muted)" }}>{m.sub}</span>
                    </div>
                    <p style={{ fontSize: "0.85rem", color: "var(--text-muted)", marginTop: "0.25rem", lineHeight: 1.6 }}>{m.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </FadeIn>
      </Sec>

      {/* Checklist */}
      <Sec alt>
        <FadeIn><SHd title={L(t.checkTitle)} desc={L(t.checkDesc)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div className="card narrow-card">
            <div className="checklist-grid">
              {CHECKLIST[lang].map((c, i) => (
                <div key={c.item} className="check-item">
                  <div className="check-number">{i + 1}</div>
                  <div className="check-copy">
                    <span className={c.gate ? "check-text check-text-gated" : "check-text"}>{c.item}</span>
                    {c.gate && <span className="tag check-gate tag-accent">{L(inline.askGate)}</span>}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </FadeIn>
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Anti-Rationalization — Accordion (expand/collapse)
          ══════════════════════════════════════════════════════════════ */}
      <Sec glow>
        <FadeIn><SHd title={L(t.shieldTitle)} desc={L(t.shieldDesc)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div className="desktop-only" data-testid="excuses-desktop" style={{ maxWidth: "48rem", margin: "0 auto" }}>
            <Accordion items={excuseAccordionItems} />
          </div>
        </FadeIn>
        <MobileExcuseCards L={L} />
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Failure Mode Framework — SpotlightCard
          ══════════════════════════════════════════════════════════════ */}
      <Sec alt>
        <FadeIn><SHd title={L(t.failTitle)} desc={L(t.failDesc)} /></FadeIn>
        <Stagger className="responsive-grid grid-2">
          {FAILURE_MODES[lang].map(fm => (
            <StaggerItem key={fm.title}>
              <SpotlightCard>
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem", marginBottom: "0.5rem" }}>
                  <span style={{ fontSize: "1.25rem" }}>{fm.icon}</span>
                  <strong style={{ fontSize: "0.95rem" }}>{fm.title}</strong>
                </div>
                <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.875rem", lineHeight: 1.6, fontStyle: "italic" }}>{fm.signal}</p>
                <div style={{ display: "flex", gap: "0.375rem", flexWrap: "wrap" as const, alignItems: "center" }}>
                  <span style={{ fontSize: "0.7rem", color: "var(--text-muted)", marginRight: "0.25rem" }}>{"→"}</span>
                  {fm.chain.map((step, i) => (
                    <span key={step} className={i === fm.chain.length - 1 ? "tag tag-accent" : "tag"} style={{ fontSize: "0.72rem" }}>{step}</span>
                  ))}
                </div>
              </SpotlightCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Benchmark — AnimatedTabs (layoutId sliding indicator) +
                      NumberTicker for stats + Marquee for scores
          ══════════════════════════════════════════════════════════════ */}
      <Sec id="benchmark" glow>
        <FadeIn><SHd title={L(t.benchTitle)} desc={L(t.benchDesc)} /></FadeIn>

        {/* Marquee strip: all 10 styles scrolling */}
        <FadeIn delay={0.1}>
          <div style={{ marginBottom: "2rem" }}>
          <Marquee speed={25} className="marquee-container">
            {BENCHMARKS.map(b => {
              const avg = Math.round(Object.values(b.metrics).reduce((a, v) => a + v, 0) / 4)
              return (
                <button
                  key={b.name}
                  className="marquee-pill"
                  onClick={() => setActiveTab(b.name)}
                  style={{ cursor: "pointer", border: activeTab === b.name ? "1px solid rgba(173,250,27,0.4)" : undefined }}
                >
                  {b.name}
                  <span className="pill-score">{avg}%</span>
                </button>
              )
            })}
          </Marquee>
          </div>
        </FadeIn>

        {/* Stats grid with NumberTicker */}
        <Stagger className="stats-grid">
          {BENCHMARKS.map(b => {
            const avg = Math.round(Object.values(b.metrics).reduce((a, v) => a + v, 0) / 4)
            return (
              <StaggerItem key={b.name}>
                <SpotlightCard className="spotlight-card" spotlightColor={activeTab === b.name ? "rgba(173, 250, 27, 0.12)" : "rgba(173, 250, 27, 0.04)"}>
                  <div style={{ textAlign: "center", cursor: "pointer" }} onClick={() => setActiveTab(b.name)}>
                    <NumberTicker className="stat-num" value={`${avg}`} suffix="%" />
                    <div style={{ fontWeight: 600, fontSize: "0.85rem", marginTop: "0.25rem" }}>{b.name}</div>
                    <div className="stat-label">{L(inline.overallScore)}</div>
                  </div>
                </SpotlightCard>
              </StaggerItem>
            )
          })}
        </Stagger>

        {/* AnimatedTabs for benchmark detail */}
        <FadeIn delay={0.2}>
          <div style={{ marginTop: "1.5rem" }}>
            <AnimatedTabs
              tabs={benchmarkTabs}
              activeTab={activeTab}
              onChange={setActiveTab}
              layoutId="benchmark-tabs"
            />
            <div className="card benchmark-panel">
              <div style={{ marginBottom: "1rem" }}>
                <strong style={{ fontSize: "1rem" }}>{activeBenchmark.name}</strong>
                <span className="inline-meta">{L(activeBenchmark.style)}</span>
                <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginTop: "0.5rem", lineHeight: 1.65 }}>{L(activeBenchmark.desc)}</p>
              </div>
              <div className="quote-block" style={{ marginBottom: "1.25rem" }}>"{L(activeBenchmark.sample)}"</div>
              <div>
                {(Object.keys(activeBenchmark.metrics) as Array<keyof typeof activeBenchmark.metrics>).map(k => (
                  <div key={k} className="bench-bar">
                    <div className="bench-label">{L(METRIC_LABELS[k])}</div>
                    <AnimatedBar value={activeBenchmark.metrics[k]} />
                  </div>
                ))}
              </div>
              <SectionGrid cols="summary" className="benchmark-summary">
                {benchmarkSummary.map((summary) => (
                  <div key={summary.label} className="summary-stat">
                    <div className="summary-stat-value">{summary.val}</div>
                    <div className="stat-label">{summary.label}</div>
                  </div>
                ))}
              </SectionGrid>
            </div>
          </div>
        </FadeIn>

        <FadeIn delay={0.2}>
          <div className="card" style={{ marginTop: "1rem" }}>
            <div style={{ marginBottom: "1.25rem" }}>
              <strong style={{ fontSize: "0.95rem" }}>{L(inline.testedData)}</strong>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginTop: "0.25rem" }}>
                {L(inline.testedDataDesc)}
              </p>
            </div>
            <SectionGrid cols="5" className="stat-grid-compact">
              {benchmarkStats.map((s) => (
                <div key={s.key} className="stat-card">
                  <NumberTicker className="stat-num" value={s.val} />
                  <div className="stat-label">{s.label}</div>
                </div>
              ))}
            </SectionGrid>
          </div>
        </FadeIn>
      </Sec>

      {/* Scenarios */}
      <Sec alt id="scenarios">
        <FadeIn><SHd title={L(t.scenarioTitle)} desc={L(t.scenarioDesc)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div className="table-shell desktop-only" data-testid="scenarios-desktop">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: "18%" }}>Scenario</th>
                  <th style={{ width: "41%" }}>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: "0.375rem" }}>
                      <span style={{ width: "0.5rem", height: "0.5rem", borderRadius: "50%", background: "var(--text-muted)", display: "inline-block" }} />
                      Without
                    </span>
                  </th>
                  <th style={{ width: "41%" }}>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: "0.375rem" }}>
                      <span style={{ width: "0.5rem", height: "0.5rem", borderRadius: "50%", background: "var(--accent)", display: "inline-block" }} />
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
                        <span className="tag tag-accent" style={{ fontSize: "0.65rem", fontFamily: "var(--font-mono)" }}>{s.delta}</span>
                        <span className="tag" style={{ fontSize: "0.65rem" }}>{L(inline.tested)}</span>
                      </div>
                    </td>
                    <td>{s.without}</td>
                    <td style={{ color: "var(--text-secondary)" }}>{s.with}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </FadeIn>
        <MobileScenarioCards lang={lang} L={L} />
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Corporate Styles — SpotlightCard grid
          ══════════════════════════════════════════════════════════════ */}
      <Sec glow>
        <FadeIn><SHd title={L(t.corpTitle)} desc={L(t.corpDesc)} /></FadeIn>
        <Stagger className="responsive-grid grid-2">
          {BENCHMARKS.map(b => (
            <StaggerItem key={b.name}>
              <SpotlightCard>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "0.375rem" }}>
                  <strong style={{ fontSize: "1rem" }}>{b.name}</strong>
                  <span className="tag tag-accent">{Math.round(Object.values(b.metrics).reduce((a, v) => a + v, 0) / 4)}%</span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "var(--text-muted)", marginBottom: "0.625rem" }}>{L(b.style)}</div>
                <p style={{ fontSize: "0.875rem", color: "var(--text-secondary)", lineHeight: 1.65, marginBottom: "0.75rem" }}>{L(b.desc)}</p>
                <div className="quote-block">"{L(b.sample)}"</div>
              </SpotlightCard>
            </StaggerItem>
          ))}
        </Stagger>
      </Sec>

      {/* Graceful Exit */}
      <Sec alt>
        <FadeIn><SHd title={L(t.exitTitle)} /></FadeIn>
        <FadeIn delay={0.1}>
          <div style={{ maxWidth: "42rem", margin: "0 auto" }}>
          <GlowBorder>
            <div className="glow-border-inner">
              <p style={{ fontSize: "0.9rem", color: "var(--text-secondary)", lineHeight: 1.75 }}>{L(t.exitDesc)}</p>
            </div>
          </GlowBorder>
          </div>
        </FadeIn>
      </Sec>

      {/* ══════════════════════════════════════════════════════════════
          Usage — AnimatedTabs for install platforms
          ══════════════════════════════════════════════════════════════ */}
      <Sec id="install" glow>
        <FadeIn><SHd title={L(t.usageTitle)} /></FadeIn>
        <Stagger className="responsive-grid grid-2-tight narrow-grid">
          <StaggerItem>
            <SpotlightCard>
              <div style={{ marginBottom: "0.5rem" }}>
                <span className="tag tag-accent" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>AUTO</span>
              </div>
              <strong style={{ display: "block", marginBottom: "0.5rem" }}>{L(inline.autoTrigger)}</strong>
              <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", lineHeight: 1.65 }}>
                {L(inline.autoTriggerDesc)}
              </p>
            </SpotlightCard>
          </StaggerItem>
          <StaggerItem>
            <SpotlightCard>
              <div style={{ marginBottom: "0.5rem" }}>
                <span className="tag" style={{ fontSize: "0.65rem", letterSpacing: "0.06em" }}>MANUAL</span>
              </div>
              <strong style={{ display: "block", marginBottom: "0.5rem" }}>{L(inline.manual)}</strong>
              <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginBottom: "0.75rem", lineHeight: 1.65 }}>
                {L(inline.manualDesc)}
              </p>
              <div className="code-inline">
                /pua
                <CopyBtn text="/pua" />
              </div>
            </SpotlightCard>
          </StaggerItem>
        </Stagger>
        <FadeIn delay={0.15}>
          <div className="narrow-block install-block">
            <InstallTabs L={L} />
          </div>
        </FadeIn>
      </Sec>

      {/* Pairs */}
      <Sec alt>
        <FadeIn><SHd title={L(t.pairsTitle)} /></FadeIn>
        <Stagger className="responsive-grid grid-2-tight narrow-grid">
          <StaggerItem>
            <SpotlightCard>
              <code style={{ fontSize: "0.85rem", fontFamily: "var(--font-mono)", display: "block", marginBottom: "0.5rem", color: "var(--accent)" }}>
                superpowers:systematic-debugging
              </code>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>
                {L(inline.pairsDesc1)}
              </p>
            </SpotlightCard>
          </StaggerItem>
          <StaggerItem>
            <SpotlightCard>
              <code style={{ fontSize: "0.85rem", fontFamily: "var(--font-mono)", display: "block", marginBottom: "0.5rem", color: "var(--accent)" }}>
                superpowers:verification-before-completion
              </code>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", lineHeight: 1.6 }}>
                {L(inline.pairsDesc2)}
              </p>
            </SpotlightCard>
          </StaggerItem>
        </Stagger>
      </Sec>

      {/* Footer */}
      <footer>
        <p>
          {L(inline.builtBy)}{" "}
          <a href="https://github.com/tanweai" target="_blank" rel="noopener noreferrer">{"探微安全实验室"}</a>
          {L(inline.builtByDesc)}
        </p>
        <p style={{ marginTop: "0.5rem", display: "flex", gap: "1rem", justifyContent: "center", flexWrap: "wrap" }}>
          <a href="https://t.me/+wBWh6h-h1RhiZTI1" target="_blank" rel="noopener noreferrer" style={{ display: "inline-flex", alignItems: "center", gap: "0.3rem" }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>
            Telegram
          </a>
          <a href="https://discord.gg/EcyB3FzJND" target="_blank" rel="noopener noreferrer">Discord</a>
          <a href="https://x.com/VeryLuckyManHa" target="_blank" rel="noopener noreferrer">Twitter/X</a>
          <a href="https://github.com/tanweai/pua" target="_blank" rel="noopener noreferrer">GitHub</a>
        </p>
        <p style={{ marginTop: "0.5rem", fontSize: "0.8rem" }}>MIT License</p>
      </footer>
    </div>
  )
}
