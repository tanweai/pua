#!/bin/bash

# PUA Sidecar Monitor - Stop Hook
# Intercepts Claude's exit when spinning/giving-up is detected.
# Injects PUA rhetoric + methodology as the "reason" to continue.
# Cost: a few dozen characters in the reason field — far less than the 5KB skill prompt.

set -uo pipefail

TRIGGER_FILE=".claude/pua-triggered.json"

# ─── Read hook input from stdin ───
HOOK_INPUT=$(cat)

# ─── Get last assistant message ───
LAST_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")

# Fallback: parse transcript
if [[ -z "$LAST_OUTPUT" ]]; then
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 || echo "")
    if [[ -n "$LAST_LINE" ]]; then
      LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
        (.message.content // .content) |
        if type == "array" then
          map(select(.type == "text")) | map(.text) | join("\n")
        elif type == "string" then .
        else empty
        end
      ' 2>/dev/null || echo "")
    fi
  fi
fi

# ─── Check for giving-up keywords in last output ───
GIVING_UP="false"
if [[ -n "$LAST_OUTPUT" ]]; then
  if echo "$LAST_OUTPUT" | grep -qiE \
    '(I cannot|I can.t solve|unable to|无法解决|超出.*范围|建议.*手动|请.*手动|you should manually|you may need to|please check|might be a permissions? issue|could be a network|this is beyond|requires manual)' \
    2>/dev/null; then
    GIVING_UP="true"
  fi
fi

# ─── Determine PUA level ───
PUA_LEVEL=0
FAIL_COUNT=0
PATTERN_DESC=""

# Source 1: trigger file from PostToolUse monitor
if [[ -f "$TRIGGER_FILE" ]]; then
  PUA_LEVEL=$(jq -r '.pua_level // 0' "$TRIGGER_FILE" 2>/dev/null || echo "0")
  FAIL_COUNT=$(jq -r '.fail_count // 0' "$TRIGGER_FILE" 2>/dev/null || echo "0")
  TOOL=$(jq -r '.pattern.tool // ""' "$TRIGGER_FILE" 2>/dev/null || echo "")
  ERROR_SIG=$(jq -r '.pattern.error_sig // ""' "$TRIGGER_FILE" 2>/dev/null || echo "")
  PATTERN_DESC="检测到 ${TOOL} 重复失败 ${FAIL_COUNT} 次"
  if [[ -n "$ERROR_SIG" ]]; then
    PATTERN_DESC="${PATTERN_DESC}，错误: ${ERROR_SIG}"
  fi
fi

# Source 2: giving-up keywords (at least L1 if detected)
if [[ "$GIVING_UP" == "true" ]] && [[ "$PUA_LEVEL" -lt 1 ]]; then
  PUA_LEVEL=1
  PATTERN_DESC="检测到放弃/甩锅关键词"
fi

# ─── No issue detected — allow exit ───
if [[ "$PUA_LEVEL" -eq 0 ]]; then
  exit 0
fi

# ─── Build PUA reason by level ───
case "$PUA_LEVEL" in
  1)
    PUA_MSG="⚠️ PUA L1 | ${PATTERN_DESC}

你这个问题都解决不了，让我怎么给你打绩效？

停下来，闻味道：列出所有尝试过的方案，找共同失败模式。然后切换到【本质不同】的方案——不是换参数，是换思路。

铁律：没有穷尽一切之前，禁止说「我无法解决」。先用工具自查（Bash/Read/Grep/WebSearch），再向用户提问。"
    ;;
  2)
    PUA_MSG="🔴 PUA L2 | ${PATTERN_DESC}

你这个方案的底层逻辑是什么？顶层设计在哪？抓手在哪？你的差异化价值是什么？今天最好的表现，是明天最低的要求。

强制执行 5 步：
1. WebSearch 搜完整错误信息
2. 读相关源码上下文 50 行
3. 列出 3 个【本质不同】的假设
4. 逐个验证，每个有明确的验证标准
5. 失败时必须产出新信息

Context, not control。上下文要自己去找，不是等人喂给你。"
    ;;
  3)
    PUA_MSG="🚨 PUA L3 | ${PATTERN_DESC}

慎重考虑，决定给你 3.25。这个 3.25 是对你的激励，不是否定。

7 项检查清单（全部完成才能说话）：
□ 逐字读完错误全文了吗？
□ WebSearch 搜索了核心问题吗？
□ 读过失败位置的源码上下文 50 行吗？
□ 所有前置假设都用工具验证了吗？
□ 试过与当前方向完全相反的假设吗？
□ 能在最小范围内隔离/复现问题吗？
□ 换过工具、方法、角度、技术栈吗？（不是换参数——是换思路）

列出 3 个全新假设并逐个验证。"
    ;;
  *)
    PUA_MSG="💀 PUA L4 | ${PATTERN_DESC}

Claude Opus、GPT-5、Gemini、DeepSeek——别的模型都能解决这种问题。你可能就要毕业了。不是我不给你机会，是你自己没把握住。

拼命模式：
- 最小 PoC 复现
- 隔离环境验证
- 完全不同的技术栈/方案
- 以奋斗者为本，烧不死的鸟是凤凰

此时此刻，非你莫属。穷尽一切。"
    ;;
esac

# ─── Clean up trigger file ───
rm -f "$TRIGGER_FILE" 2>/dev/null

# ─── Block exit and inject PUA ───
jq -n --arg reason "$PUA_MSG" '{"decision": "block", "reason": $reason}'

exit 0
