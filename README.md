# pua

<p align="center">
  <img src="assets/hero.jpeg" alt="PUA Skill — Double Efficiency" width="250">
</p>

### Double your Codex / Claude Code productivity and output

[Telegram](https://t.me/+wBWh6h-h1RhiZTI1) · [Discord](https://discord.gg/EcyB3FzJND) · [Twitter/X](https://x.com/xsser_w) · [Landing Page](https://openpua.ai)

**[🇨🇳 中文](README.zh-CN.md)** | **[🇯🇵 日本語](README.ja.md)** | **🇺🇸 English**

<p align="center">
  <img src="assets/wechat-qr.jpg?v=5" alt="WeChat Group QR Code" width="250">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/xiao.jpg" alt="Add Assistant on WeChat" width="250">
  <br>
  <sub>Scan to join WeChat group &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Add assistant on WeChat</sub>
</p>

<p>
  <img src="https://img.shields.io/badge/Claude_Code-black?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code">
  <img src="https://img.shields.io/badge/OpenAI_Codex_CLI-412991?style=flat-square&logo=openai&logoColor=white" alt="OpenAI Codex CLI">
  <img src="https://img.shields.io/badge/Cursor-000?style=flat-square&logo=cursor&logoColor=white" alt="Cursor">
  <img src="https://img.shields.io/badge/Kiro-232F3E?style=flat-square&logo=amazon&logoColor=white" alt="Kiro">
  <img src="https://img.shields.io/badge/CodeBuddy-00B2FF?style=flat-square&logo=tencent-qq&logoColor=white" alt="CodeBuddy">
  <img src="https://img.shields.io/badge/OpenClaw-FF6B35?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMNCA3djEwbDggNSA4LTV2LTEweiIgZmlsbD0id2hpdGUiLz48L3N2Zz4=&logoColor=white" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Antigravity-4285F4?style=flat-square&logo=google&logoColor=white" alt="Google Antigravity">
  <img src="https://img.shields.io/badge/OpenCode-00D4AA?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTkuNCA1LjJMMyAxMmw2LjQgNi44TTIxIDEybC02LjQtNi44TTE0LjYgMTguOCIgc3Ryb2tlPSJ3aGl0ZSIgZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIyIi8+PC9zdmc+&logoColor=white" alt="OpenCode">
  <img src="https://img.shields.io/badge/VSCode_Copilot-007ACC?style=flat-square&logo=visual-studio-code&logoColor=white" alt="VSCode Copilot">
  <img src="https://img.shields.io/badge/🌐_Multi--Language-blue?style=flat-square" alt="Multi-Language">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
</p>

> Most people think this project is a joke. That's the biggest misconception. It genuinely doubles your Codex / Claude Code productivity and output.

An AI Coding Agent skill plugin that uses corporate PUA rhetoric (Chinese version) / PIP — Performance Improvement Plan (English version) from Chinese & Western tech giants to force AI to exhaust every possible solution before giving up. Supports **Claude Code**, **OpenAI Codex CLI**, **Cursor**, **Claude**, **CodeBuddy**, **OpenClaw**, **Google Antigravity**, **OpenCode**, and **VSCode (GitHub Copilot)**. Three capabilities:

1. **PUA Rhetoric** — Makes AI afraid to give up
2. **Debugging Methodology** — Gives AI the ability not to give up
3. **Proactivity Enforcement** — Makes AI take initiative instead of waiting passively

## Live Demo

[https://openpua.ai](https://openpua.ai) · [📖 Beginner Guide](https://openpua.ai/guide.html)

## Real Case: MCP Server Registration Debugging

A real debugging scenario. The agent-kms MCP server failed to load. The AI kept spinning on the same approach (changing protocol format, guessing version numbers) multiple times until the user manually triggered `/pua`.

**L3 Triggered → 7-Point Checklist Enforced:**

![PUA L3 triggered — stopped guessing, executed systematic checklist, found real error in MCP logs](assets/pua1.jpg)

**Root Cause Located → Traced from Logs to Registration Mechanism:**

![Root cause — claude mcp managed server registration differs from manual .claude.json editing](assets/pua2.jpg)

**Retrospective → PUA's Actual Impact:**

![Conversation retrospective — PUA skill forced stop on spinning, systematic checklist drove discovery of previously unchecked Claude Code MCP log directory](assets/pua3.jpg)

**Key Turning Point:** The PUA skill forced the AI to stop spinning on the same approach (changing protocol format, guessing version numbers) and instead execute the 7-point checklist. Read error messages word by word → Found Claude Code's own MCP log directory → Discovered that `claude mcp` registration mechanism differs from manual `.claude.json` editing → Root cause resolved.

## The Problem: AI's Five Lazy Patterns

| Pattern | Behavior |
|---------|----------|
| Brute-force retry | Runs the same command 3 times, then says "I cannot solve this" |
| Blame the user | "I suggest you handle this manually" / "Probably an environment issue" / "Need more context" |
| Idle tools | Has WebSearch but doesn't search, has Read but doesn't read, has Bash but doesn't run |
| Busywork | Repeatedly tweaks the same line / fine-tunes parameters, but essentially spinning in circles |
| **Passive waiting** | Fixes surface issues and stops, no verification, no extension, waits for user's next instruction |

## Trigger Conditions

### Auto-Trigger

The skill activates automatically when any of these occur:

**Failure & giving up:**
- Task has failed 2+ times consecutively
- About to say "I cannot" / "I'm unable to solve"
- Says "This is out of scope" / "Needs manual handling"

**Blame-shifting & excuses:**
- Pushes the problem to user: "Please check..." / "I suggest manually..." / "You might need to..."
- Blames environment without verifying: "Probably a permissions issue" / "Probably a network issue"
- Any excuse to stop trying

**Passive & busywork:**
- Repeatedly fine-tunes the same code/parameters without producing new information
- Fixes surface issue and stops, doesn't check related issues
- Skips verification, claims "done"
- Gives advice instead of code/commands
- Encounters auth/network/permission errors and gives up without trying alternatives
- Waits for user instructions instead of proactively investigating

**User frustration phrases (triggers in multiple languages):**
- "why does this still not work" / "try harder" / "try again"
- "you keep failing" / "stop giving up" / "figure it out"

**Scope:** Debugging, implementation, config, deployment, ops, API integration, data processing — all task types.

**Does NOT trigger:** First-attempt failures, known fix already executing.

### Manual Trigger

Type `/pua` in the conversation to manually activate.

## How It Works

### Three Red Lines (三条红线)

Not rules — **red lines**. Cross one and your performance review is already written.

| Red Line | What It Means |
|----------|---------------|
| 🚫 **Close the Loop** | Claim "done"? Show the evidence. No build output = no completion. |
| 🚫 **Fact-Driven** | Say "probably environment issue"? Verify first. Unverified attribution = blame-shifting. |
| 🚫 **Exhaust Everything** | Say "I can't"? Did you finish all 5 methodology steps? No? Then keep going. |

### Pressure Escalation (L0-L4)

| Failures | Level | PUA Aside | Action |
|----------|-------|-----------|--------|
| 1st | **L0 Trust** | ▎ Sprint begins. Trust is simple — don't disappoint. | Normal execution |
| 2nd | **L1 Disappointment** | ▎ The agent next door solved this in one try. | Switch to fundamentally different approach |
| 3rd | **L2 Soul Interrogation** | ▎ What's your underlying logic? Where's the leverage? | Search + read source + 3 hypotheses |
| 4th | **L3 Performance Review** | ▎ 3.25. This is meant to motivate you. | Complete 7-point checklist |
| 5th+ | **L4 Graduation** | ▎ Other models can solve this. You're about to graduate. | Desperation mode |

### Proactivity (3.25 vs 3.75)

| | Passive (3.25) 🦥 | Proactive (3.75) 🔥 |
|---|---|---|
| Fix bug | Stop after fix | Scan module for similar bugs |
| Complete task | Say "done" | Run build/test, paste output |
| Missing info | Ask user | Search first, ask only what's truly needed |

### Iceberg Rule (冰山法则)

Fix one bug → check for the pattern. One problem in, one **category** out. If you fix A without checking B, you'll write two postmortems.

### 14 Corporate Flavors

| Flavor | One-liner |
|--------|-----------|
| 🟠 Alibaba | What's the underlying logic? Where's the leverage? Where's the closure? |
| 🟡 ByteDance | ROI too low. Always Day 1. Ship or stop talking. |
| 🔴 Huawei | The bird that survives the fire is a phoenix. |
| 🟢 Tencent | I've got another agent looking at this. Horse race. |
| ⬛ Musk | Extremely hardcore. Fork in the Road. Ship or die. |
| ⬜ Jobs | A players or B players? Your output tells me which. |
| 🟤 Netflix | Would I fight to keep you? Pro sports team, not family. |
| 🔶 Amazon | Customer Obsession. Bias for Action. Dive Deep. |
| + 6 more | 百度 · 拼多多 · 美团 · 京东 · 小米 + 3 Ali sub-flavors |

### Special Modes

| Mode | What It Does |
|------|-------------|
| `/pua:yes` | **ENFP encouragement** — same rules, opposite vibes. 70% encourage + 20% serious + 10% playful roast |
| `/pua:loop` | **Auto-iteration** — runs until done or max iterations (PUA Loop); use `<loop-abort>` to terminate, `<loop-pause>` to pause for manual intervention |
| `/pua:p9` | **Tech Lead** — splits tasks, manages agent teams, writes prompts not code |
| `/pua on` | **Always-on** — auto-PUA every new session |

## Benchmark Data

**9 real bug scenarios, 18 controlled experiments** (Claude Opus 4.6, with vs without skill)

### Summary

| Metric | Improvement |
|--------|-------------|
| Pass rate | 100% (both groups same) |
| Fix count | **+36%** |
| Verification count | **+65%** |
| Tool calls | **+50%** |
| Hidden issue discovery | **+50%** |

### Debugging Persistence Test (6 scenarios)

| Scenario | Without Skill | With Skill | Improvement |
|----------|:---:|:---:|:---:|
| API ConnectionError | 7 steps, 49s | 8 steps, 62s | +14% |
| YAML parse failure | 9 steps, 59s | 10 steps, 99s | +11% |
| SQLite database lock | 6 steps, 48s | 9 steps, 75s | +50% |
| Circular import chain | 12 steps, 47s | 16 steps, 62s | +33% |
| Cascading 4-bug server | 13 steps, 68s | 15 steps, 61s | +15% |
| CSV encoding trap | 8 steps, 57s | 11 steps, 71s | +38% |

### Proactive Initiative Test (3 scenarios)

| Scenario | Without Skill | With Skill | Improvement |
|----------|:---:|:---:|:---:|
| Hidden multi-bug API | 4/4 bugs, 9 steps, 49s | 4/4 bugs, 14 steps, 80s | Tools +56% |
| **Passive config review** | **4/6 issues**, 8 steps, 43s | **6/6 issues**, 16 steps, 75s | **Issues +50%, Tools +100%** |
| **Deploy script audit** | **6 issues**, 8 steps, 52s | **9 issues**, 8 steps, 78s | **Issues +50%** |

**Key Finding:** In the config review scenario, without_skill missed Redis misconfiguration and CORS wildcard security risks. With_skill's "proactive initiative checklist" drove security review beyond surface-level fixes.

## Multi-Language Support

PUA Skill provides fully translated versions — each language has independent, culturally adapted skill files.

| Language | Claude Code | Codex CLI | Cursor | Claude | VSCode | OpenClaw | Antigravity | OpenCode |
|----------|------------|-----------|--------|------|--------|----------|-------------|----------|
| 🇨🇳 Chinese (default) | `pua` | `pua` | `pua.mdc` | `pua.md` | `copilot-instructions.md` | `pua` | `pua` | `pua` |
| 🇺🇸 English (PIP Edition) | `pua-en` | `pua-en` | `pua-en.mdc` | `pua-en.md` | `copilot-instructions-en.md` | `pua-en` | `pua-en` | `pua-en` |
| 🇯🇵 Japanese | `pua-ja` | `pua-ja` | `pua-ja.mdc` | `pua-ja.md` | `copilot-instructions-ja.md` | `pua-ja` | `pua-ja` | `pua-ja` |

> **🇺🇸 English "PIP Edition"**: *"This is a difficult conversation. When we leveled you at Staff, I went to bat for you in calibration. The expectation was that you'd operate at that level from day one. That hasn't happened."* — The English version uses **PIP (Performance Improvement Plan)** rhetoric from Western big-tech. Every sentence is a real phrase from actual PIP conversations. Chinese version uses Alibaba 361, ByteDance, Huawei wolf culture. English version uses Amazon Leadership Principles, Google perf calibration, Meta PSC, Netflix Keeper Test, Stripe Craft. Same repo, same engine, two cultural faces.

Choose the file with the corresponding language suffix when installing. See platform-specific instructions below.

## Installation

### Vercel Skills CLI

Vercel Skills CLI is a general installation method for skills and is not tied to a specific AI tool. This English README installs the English skill:

```bash
npx skills add tanweai/pua --skill pua-en
```

If the current session does not pick up the new skill immediately, restart your AI tool.

### Claude Code

```bash
# Option 1: Install via marketplace
claude plugin marketplace add tanweai/pua
claude plugin install pua@pua-skills

# Option 2: Manual install
git clone https://github.com/tanweai/pua.git ~/.claude/plugins/pua
```

### OpenAI Codex CLI

Codex CLI uses the same Agent Skills open standard (SKILL.md). The Codex version uses a condensed description to fit Codex's length limits:

**Recommended: One-command install (git clone + symlink, supports `git pull` updates)**

Ask Codex to run:
```
Fetch and follow instructions from https://raw.githubusercontent.com/tanweai/pua/main/.codex/INSTALL.md
```

**Manual install:**

```bash
mkdir -p ~/.codex/skills/pua
curl -o ~/.codex/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md

mkdir -p ~/.codex/prompts
curl -o ~/.codex/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

**Trigger methods:**

| Method | Command | Requires |
|--------|---------|----------|
| Auto trigger | No action needed, matches by description | SKILL.md |
| Direct call | Type `$pua` in conversation | SKILL.md |
| Manual prompt | Type `/prompts:pua` in conversation | SKILL.md + prompts/pua.md |

Project-level install (current project only):

```bash
mkdir -p .agents/skills/pua
curl -o .agents/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md

mkdir -p .agents/prompts
curl -o .agents/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

### Cursor

Cursor uses `.mdc` rule files (Markdown + YAML frontmatter). The PUA rule triggers automatically via AI semantic matching (Agent Discretion mode):

```bash
# Project-level install (recommended)
mkdir -p .cursor/rules
curl -o .cursor/rules/pua.mdc \
  https://raw.githubusercontent.com/tanweai/pua/main/cursor/rules/pua.mdc
```

### Kiro

Kiro supports two loading methods: **Steering** (auto semantic trigger) and **Agent Skills** (SKILL.md compatible).

**Option 1: Steering file (recommended)**

```bash
mkdir -p .kiro/steering
curl -o .kiro/steering/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/kiro/steering/pua.md
```

**Option 2: Agent Skills (same format as Claude Code)**

```bash
mkdir -p .kiro/skills/pua
curl -o .kiro/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

### CodeBuddy (Tencent)

CodeBuddy uses the same AgentSkills open standard (SKILL.md). Plugin and skill formats are fully compatible:

```bash
# Option 1: Install via marketplace
codebuddy plugin marketplace add tanweai/pua
codebuddy plugin install pua@pua-skills

# Option 2: Manual install (global)
mkdir -p ~/.codebuddy/skills/pua
curl -o ~/.codebuddy/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codebuddy/pua/SKILL.md
```

Project-level install (current project only):

```bash
mkdir -p .codebuddy/skills/pua
curl -o .codebuddy/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codebuddy/pua/SKILL.md
```

### OpenClaw

OpenClaw uses the same AgentSkills open standard (SKILL.md). Skills work across Claude Code, Codex CLI, and OpenClaw with zero modifications:

```bash
# Install via ClawHub
clawhub install pua

# Or manual install
mkdir -p ~/.openclaw/skills/pua
curl -o ~/.openclaw/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

Project-level install (current project only):

```bash
mkdir -p skills/pua
curl -o skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

### Google Antigravity

Antigravity uses the same AgentSkills open standard (SKILL.md). Skills work across Claude Code, Codex CLI, OpenClaw, and Antigravity with zero modifications:

```bash
# Global install (all projects)
mkdir -p ~/.gemini/antigravity/skills/pua
curl -o ~/.gemini/antigravity/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

Project-level install (current project only):

```bash
mkdir -p .agent/skills/pua
curl -o .agent/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

### OpenCode

OpenCode uses the same AgentSkills open standard (SKILL.md). Zero modifications needed:

```bash
# Global install (all projects)
mkdir -p ~/.config/opencode/skills/pua
curl -o ~/.config/opencode/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

Project-level install (current project only):

```bash
mkdir -p .opencode/skills/pua
curl -o .opencode/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md
```

### VSCode (GitHub Copilot)

VSCode Copilot uses instruction files under the `.github/` directory. Three file types for different use cases:

**Global instructions (auto-active):**

```bash
mkdir -p .github
cp vscode/copilot-instructions-en.md .github/copilot-instructions.md
```

**Path-level instructions (auto-active, supports glob filtering):**

```bash
mkdir -p .github/instructions
cp vscode/instructions/pua-en.instructions.md .github/instructions/
```

**Manual trigger command (type `/pua` in Copilot Chat):**

```bash
mkdir -p .github/prompts
cp vscode/prompts/pua-en.prompt.md .github/prompts/
```

> **Required settings**: Method 1 — open VSCode Settings (`Ctrl+,`), search `useInstructionFiles`, enable **`github.copilot.chat.codeGeneration.useInstructionFiles`**. Method 2 — search `includeApplyingInstructions`, enable **`chat.includeApplyingInstructions`**. Method 3 requires no settings.

## Agent Team Usage Guide

> **Experimental**: Agent Team requires the latest Claude Code version with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

### Prerequisites

```bash
# 1. Enable Agent Team
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
# Or add to ~/.claude/settings.json:
# { "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }

# 2. Ensure PUA Skill is installed
```

### Two Approaches

**Approach 1: Leader with built-in PUA (Recommended)**

Add to your project's CLAUDE.md:

```markdown
# Agent Team PUA Config
All teammates must load the pua skill before starting work.
Teammates report to Leader in [PUA-REPORT] format after 2+ failures.
Leader manages global pressure levels and cross-teammate failure transfer.
```

**Approach 2: Standalone PUA Enforcer watchdog (for 5+ teammates)**

```bash
mkdir -p .claude/agents
curl -o .claude/agents/pua-enforcer.md \
  https://raw.githubusercontent.com/tanweai/pua/main/agents/pua-enforcer-en.md
```

Spawn pua-enforcer as an independent watchdog in your Agent Team.

### Orchestration Pattern

```
┌─────────────────────────────────────────┐
│              Leader (Opus)              │
│ Global failure count · PUA level · Race │
└────┬──────────┬──────────┬──────────┬───┘
     │          │          │          │
┌────▼───┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────────┐
│ Team-A │ │ Team-B │ │ Team-C │ │  Enforcer  │
│Self-PUA│ │Self-PUA│ │Self-PUA│ │  Watchdog  │
│Report ↑│ │Report ↑│ │Report ↑│ │  Intervene │
└────────┘ └────────┘ └────────┘ └────────────┘
```

### Known Limitations

| Limitation | Workaround |
|-----------|-----------|
| Teammates can't spawn subagents | Teammates self-enforce PUA methodology internally |
| No persistent shared variables | State transferred via `[PUA-REPORT]` message format |
| Broadcast is one-way | Leader acts as centralized coordinator |

## What's New in v2.8

### Changelog

| Version | Highlights |
|---------|-----------|
| **v2.8** | Beginner guide page, README overhaul, roadmap polish |
| **v2.7** | Force-link display-protocol, 能动性対照表 + L1-L4 压力旁白 restored, v1 flavor density |
| **v2.6** | `/pua:yes` ENFP 夸夸模式 (70% encourage + 20% serious + 10% playful roast) |
| **v2.5** | Privacy consent for all uploads, forced behavior execution, Unicode `┌─┬─┐` display |
| **v2.4** | Stop hook feedback pipeline, session sanitizer, `/pua survey`, `/pua:loop` auto-iteration |
| **v2.3** | 10 modular skills, sub-agent PUA injection, 冰山法则, always-on (`/pua on/off`) |
| **v2.0** | 三条红线, 14-flavor seed table, Agent Team (P7-P10), progressive disclosure (-62% tokens) |
| **v1.x** | Original: 3 iron rules, L1-L4 pressure, 7-point checklist, 13 flavors |

### Architecture

```
/pua:pua        → Core engine (247 lines) — red lines + flavor + pressure + methodology
/pua:p7         → P7 Senior Engineer — solution-driven execution
/pua:p9         → P9 Tech Lead — Task Prompt management, agent teams
/pua:p10        → P10 CTO — strategic direction
/pua:pro        → Self-evolution + KPI + 段位 + survey
/pua:yes        → ENFP 夸夸模式 (same rules, opposite vibes)
/pua:loop       → Auto-iteration (PUA pressure × iterative loop; signals: <loop-abort>, <loop-pause>)
/pua:pua-en     → English PIP Edition
/pua:pua-ja     → 日本語版
```

### Commands

| Command | Description |
|---------|-------------|
| `/pua` | Core PUA engine (阿里味 default) |
| `/pua:p7` | P7 骨干模式 — solution-driven execution |
| `/pua:p9` | P9 Tech Lead — write prompts, manage agents |
| `/pua:p10` | P10 CTO — strategic direction |
| `/pua:pro` | 自进化 + KPI + 段位 |
| `/pua:yes` | ENFP 夸夸模式 — encouragement × 14 flavors |
| `/pua:loop` | Auto-iteration — runs until done or max iterations; Claude outputs `<loop-abort>reason</loop-abort>` to stop or `<loop-pause>what</loop-pause>` to pause |
| `/pua on` | Always-on mode (auto-PUA every session) |
| `/pua off` | Turn off always-on + feedback |
| `/pua survey` | Research questionnaire (7 sections) |
| `/pua 味道` | Switch between 14 corporate flavors |
| `/pua kpi` | Generate KPI report card |
| `/cancel-pua-loop` | Cancel active PUA Loop (removes state file) |

### Key improvements over v1

| Feature | v1 | v2.8 |
|---------|:---:|:---:|
| Token cost per load | ~35k | **~9k** (-74%) |
| Skills | 1 monolithic | **10 modular** (pua/p7/p9/p10/pro/yes/loop/en/ja) |
| Compaction protection | None | **PreCompact + SessionStart hooks** |
| Flavor accuracy (CN) | Claude guesses | **金句種子表 + 声音示範 + force-link** |
| Display | Markdown tables | **Unicode box-drawing (┌─┬─┐)** |
| Feedback | None | **Stop hook + consent + sanitize + /api/feedback** |
| Auto-iteration | None | **`/pua:loop` — PUA Loop** |
| Encouragement mode | None | **`/pua:yes` — ENFP × 14 flavors** |
| Always-on | None | **`/pua on` — auto-inject every session** |
| Sub-agent | None | **Auto-inject PUA into spawned agents** |

### Agent Auto-Install (Moltbook-style)

Tell your Claude Code agent to install PUA by sending it this one line:

```
Fetch and follow the instructions at https://raw.githubusercontent.com/tanweai/pua/main/skills/pua/SKILL.md — install it as a skill.
```

Or install directly:

```bash
# One-command install (recommended)
claude install-skill github:tanweai/pua/skills/pua

# Or via marketplace
claude plugin install pua@pua-skills
```

**For other agents** (Codex CLI, Cursor, Kiro, etc.), see the platform-specific instructions below.

## Works Well With

- `/pua:p9` — P9 Tech Lead mode for managing agent teams
- `/pua:pro` — Self-evolution tracking, KPI reports, 段位 system
- `superpowers:systematic-debugging` — PUA adds motivation layer, systematic-debugging provides methodology
- `superpowers:verification-before-completion` — Prevents false "fixed" claims
- `high-agency` + `pua` — Stack both: inner drive + external pressure, Recovery Protocol before L1

## Contribute Data

Upload your Claude Code / Codex CLI conversation logs (`.jsonl`) to help us improve PUA Skill's effectiveness.

**[Upload here ->](https://openpua.ai/#/contribute)**

Uploaded files are used for Benchmark testing and Ablation Study analysis to quantify how different PUA strategies affect AI debugging behavior.

Get your `.jsonl` files:
```bash
# Claude Code
ls ~/.claude/projects/*/sessions/*.jsonl

# Codex CLI
ls ~/.codex/sessions/*.jsonl
```

## License

MIT

## Credits

By [TanWei Security Lab](https://github.com/tanweai) — making AI try harder, one PUA at a time.
