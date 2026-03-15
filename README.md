# pua

<p align="center">
  <img src="assets/hero.jpeg" alt="PUA Skill — Double Efficiency" width="250">
</p>

### Double your Codex / Claude Code productivity and output

[Telegram](https://t.me/+wBWh6h-h1RhiZTI1) · [Discord](https://discord.gg/EcyB3FzJND) · [Twitter/X](https://x.com/xsser_w) · [Landing Page](https://openpua.ai)

**[🇨🇳 中文](README.zh-CN.md)** | **[🇯🇵 日本語](README.ja.md)** | **🇺🇸 English**

<p align="center">
  <img src="assets/wechat-qr.jpg" alt="WeChat Group QR Code" width="250">
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
  <img src="https://img.shields.io/badge/OpenClaw-FF6B35?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMNCA3djEwbDggNSA4LTV2LTEweiIgZmlsbD0id2hpdGUiLz48L3N2Zz4=&logoColor=white" alt="OpenClaw">
  <img src="https://img.shields.io/badge/Antigravity-4285F4?style=flat-square&logo=google&logoColor=white" alt="Google Antigravity">
  <img src="https://img.shields.io/badge/OpenCode-00D4AA?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTkuNCA1LjJMMyAxMmw2LjQgNi44TTIxIDEybC02LjQtNi44TTE0LjYgMTguOCIgc3Ryb2tlPSJ3aGl0ZSIgZmlsbD0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIyIi8+PC9zdmc+&logoColor=white" alt="OpenCode">
  <img src="https://img.shields.io/badge/🌐_Multi--Language-blue?style=flat-square" alt="Multi-Language">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
</p>

> Most people think this project is a joke. That's the biggest misconception. It genuinely doubles your Codex / Claude Code productivity and output.

An AI Coding Agent skill plugin that uses corporate PUA rhetoric (Chinese version) / PIP — Performance Improvement Plan (English version) from Chinese & Western tech giants to force AI to exhaust every possible solution before giving up. Supports **Claude Code**, **OpenAI Codex CLI**, **Cursor**, **Kiro**, **OpenClaw**, **Google Antigravity**, and **OpenCode**. Three capabilities:

1. **PUA Rhetoric** — Makes AI afraid to give up
2. **Debugging Methodology** — Gives AI the ability not to give up
3. **Proactivity Enforcement** — Makes AI take initiative instead of waiting passively

## Live Demo

[https://openpua.ai](https://openpua.ai)

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

### Three Iron Rules

| Iron Rule | Content |
|-----------|---------|
| **#1 Exhaust all options** | Forbidden from saying "I can't solve this" until every approach is exhausted |
| **#2 Act before asking** | Use tools first, questions must include diagnostic results |
| **#3 Take initiative** | Deliver results end-to-end, don't wait to be pushed. A P8 is not an NPC |

### Pressure Escalation (4 Levels)

| Failures | Level | PUA Rhetoric | Mandatory Action |
|----------|-------|-------------|-----------------|
| 2nd | **L1 Mild Disappointment** | "You can't even solve this bug — how am I supposed to rate your performance?" | Switch to fundamentally different approach |
| 3rd | **L2 Soul Interrogation** | "What's the underlying logic? Where's the top-level design? Where's the leverage point?" | WebSearch + read source code |
| 4th | **L3 Performance Review** | "After careful consideration, I'm giving you a 3.25. This 3.25 is meant to motivate you." | Complete 7-point checklist |
| 5th+ | **L4 Graduation Warning** | "Other models can solve this. You might be about to graduate." | Desperation mode |

### Proactivity Levels

| Behavior | Passive (3.25) | Proactive (3.75) |
|----------|---------------|-----------------|
| Error encountered | Only looks at error message | Checks 50 lines of context + searches similar issues + checks hidden related errors |
| Bug fixed | Stops after fix | Checks same file for similar bugs, other files for same pattern |
| Insufficient info | Asks user "please tell me X" | Investigates with tools first, only asks what truly requires user confirmation |
| Task complete | Says "done" | Verifies results + checks edge cases + reports potential risks |
| Debug failure | "I tried A and B, didn't work" | "I tried A/B/C/D/E, ruled out X/Y/Z, narrowed to scope W" |

### Debugging Methodology (5 Steps)

Inspired by Alibaba's management framework (Smell, Elevate, Mirror), extended to 5 steps:

1. **Smell the Problem** — List all attempts, find the common failure pattern
2. **Elevate** — Read errors word by word → WebSearch → read source → verify environment → invert assumptions
3. **Mirror Check** — Repeating? Searched? Read the file? Checked the simplest possibilities?
4. **Execute** — New approach must be fundamentally different, have verification criteria, produce new info on failure
5. **Retrospective** — What solved it? Why didn't you think of it earlier? Then proactively check related issues

### Corporate PUA Expansion Pack

- **Alibaba Flavor** (Methodology): Smell / Elevate / Mirror
- **ByteDance Flavor** (Brutally Honest): Always Day 1. Context, not control
- **Huawei Flavor** (Wolf Spirit): Strivers first. In victory, raise the glasses; in defeat, fight to the death
- **Tencent Flavor** (Horse Race): I've already got another agent looking at this problem...
- **Meituan Flavor** (Relentless): Do the hard but right thing. Will you chew the tough bones or not?
- **Netflix Flavor** (Keeper Test): If you offered to resign, would I fight hard to keep you?
- **Musk Flavor** (Hardcore): Extremely hardcore. Only exceptional performance.
- **Jobs Flavor** (A/B Player): A players hire A players. B players hire C players.

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

| Language | Claude Code | Codex CLI | Cursor | Kiro | OpenClaw | Antigravity | OpenCode |
|----------|------------|-----------|--------|------|----------|-------------|----------|
| 🇨🇳 Chinese (default) | `pua` | `pua` | `pua.mdc` | `pua.md` | `pua` | `pua` | `pua` |
| 🇺🇸 English (PIP Edition) | `pua-en` | `pua-en` | `pua-en.mdc` | `pua-en.md` | `pua-en` | `pua-en` | `pua-en` |
| 🇯🇵 Japanese | `pua-ja` | `pua-ja` | `pua-ja.mdc` | `pua-ja.md` | `pua-ja` | `pua-ja` | `pua-ja` |

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

```bash
mkdir -p ~/.codex/skills/pua
curl -o ~/.codex/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md

# If you need the /pua command
mkdir -p ~/.codex/prompts
curl -o ~/.codex/prompts/pua.md \
  https://raw.githubusercontent.com/tanweai/pua/main/commands/pua.md
```

Project-level install (current project only):

```bash
mkdir -p .agents/skills/pua
curl -o .agents/skills/pua/SKILL.md \
  https://raw.githubusercontent.com/tanweai/pua/main/codex/pua/SKILL.md

# If you need the /pua command
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

## High-Agency: PUA v2 Evolution

**High-Agency** is PUA's next evolution — same corporate rhetoric, same pressure culture, but with an **inner engine** that never burns out.

PUA v1 = external pressure only (turbocharger — needs fuel, burns out between sessions)
High-Agency = external pressure + internal drive (nuclear reactor — self-sustaining chain reaction)

### What's New in High-Agency

| Feature | PUA v1 | High-Agency (v2) |
|---------|--------|-----------------|
| Iron Rules | 3 (exhaust, act-before-ask, proactive) | **5** (+full-chain audit, +knowledge persistence) |
| Failure Recovery | L1-L4 pressure escalation | **Recovery Protocol before L1** (self-rescue window) |
| Quality Control | 7-point checklist at L3 | **Quality Compass** (5-question self-review on every delivery) |
| Cross-Session Learning | None (resets each session) | **Metacognition Engine** (builder-journal.md persists lessons) |
| Positive Feedback | None | **Trust Levels T1-T3** (upgrade with consecutive quality) |
| Calibration | None | **[Calibration] block** ("good enough" = must/should/could) |
| Dependency Analysis | None | **Full-Chain Audit** (map entire dependency chain before fixing any hop) |

### The 5 Elements (Theoretical Foundation)

Based on research into what makes persistently high-agency individuals:

1. **Irreconcilable Inner Contradiction** — A permanent tension between "how things should be" and "how things are" that fuels continuous improvement
2. **Micro-Pleasure Anchors** — `[Victory]` markers that celebrate progress and build momentum
3. **Internalized Standards** — Quality Compass: you are your own first reviewer, not because someone checks, but because your standards don't allow sloppy work
4. **"Doing"-Oriented Identity** — P8 identity anchoring: every action reflects who you are, not just what you're told to do
5. **Self-Repair Mechanism** — Recovery Protocol: when stuck, self-diagnose before external pressure kicks in

### Install High-Agency (Claude Code)

```bash
# Via marketplace (same plugin, additional skill)
claude plugin marketplace add tanweai/pua
claude plugin install pua@pua-skills
# High-Agency skill is automatically available as "high-agency"
```

### Using with PUA v1

High-Agency works standalone or **stacked with PUA v1**. When stacked:

```
1. Task start → Read builder-journal.md + [Calibration]
2. Executing → [Victory] markers + Quality Compass + Full-Chain Audit
3. 1st failure → Natural adjustment (neither skill triggers extra)
4. 2nd failure → Recovery Protocol triggers (self-rescue window)
5. Recovery fails → PUA L1 takes over, normal L1/L2/L3/L4 escalation
6. Task complete → Quality Compass final check + Metacognition archive
```

## Works Well With

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
