#!/bin/bash

# PUA Loop Setup Script
# Creates state file for in-session PUA Loop
#
# Adapted from Ralph Wiggum by Anthropic (MIT License)
# https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum

set -euo pipefail

# Parse arguments
PROMPT_PARTS=()
MAX_ITERATIONS=30
COMPLETION_PROMISE="null"

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
PUA Loop - Interactive self-referential development loop

USAGE:
  /pua-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a PUA Loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>
  To terminate immediately: <loop-abort>reason</loop-abort>
  To pause for manual intervention: <loop-pause>what is needed</loop-pause>

  Use this for:
  - Interactive iteration where you want to see progress
  - Tasks requiring self-correction and refinement
  - Autonomous development with PUA quality enforcement

EXAMPLES:
  /pua-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /pua-loop --max-iterations 10 Fix the auth bug
  /pua-loop Refactor cache layer  (default: 30 iterations)
  /pua-loop --completion-promise 'TASK COMPLETE' Create a REST API

STOPPING:
  Only by reaching --max-iterations, detecting --completion-promise,
  or outputting a <loop-abort> signal. Default is 30 iterations.

MONITORING:
  # View current iteration:
  grep '^iteration:' .claude/pua-loop.local.md

  # View full state:
  head -10 .claude/pua-loop.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   You provided: --max-iterations (with no number)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        echo "" >&2
        echo "   Invalid: decimals (10.5), negative numbers (-5), text" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --completion-promise requires a text argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --completion-promise 'DONE'" >&2
        echo "     --completion-promise 'TASK COMPLETE'" >&2
        echo "     --completion-promise 'All tests passing'" >&2
        echo "" >&2
        echo "   You provided: --completion-promise (with no text)" >&2
        echo "" >&2
        echo "   Note: Multi-word promises must be quoted!" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      # Non-option argument - collect all as prompt parts
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join all prompt parts with spaces
PROMPT="${PROMPT_PARTS[*]}"

# Validate prompt is non-empty
if [[ -z "$PROMPT" ]]; then
  echo "❌ Error: No prompt provided" >&2
  echo "" >&2
  echo "   PUA Loop needs a task description to work on." >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /pua-loop Build a REST API for todos" >&2
  echo "     /pua-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /pua-loop --completion-promise 'DONE' Refactor code" >&2
  echo "" >&2
  echo "   For all options: /pua-loop --help" >&2
  exit 1
fi

# Create state file for stop hook (markdown with YAML frontmatter)
mkdir -p .claude

# Quote completion promise for YAML if it contains special chars or is not null
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Build the completion instruction line for the embedded PUA protocol
# This ensures every iteration (including after context compaction) has the right signal
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  PROTOCOL_COMPLETION="6. 只有当任务完全完成且验证通过时，输出 <promise>${COMPLETION_PROMISE//\"/}</promise>"
else
  PROTOCOL_COMPLETION="6. 此 loop 无完成信号，将持续运行直到 --max-iterations 上限"
fi

cat > .claude/pua-loop.local.md <<EOF
---
active: true
iteration: 1
session_id: ${CLAUDE_CODE_SESSION_ID:-}
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT

== PUA 行为协议（每次迭代必须遵守）==
1. 读取项目文件和 git log，了解上次做了什么
2. 按三条红线执行：闭环验证、事实驱动、穷尽一切方案
3. 跑 build/test 验证改动，不要跳过
4. 发现问题就修，修完再验证（不声称完成，先验证）
5. 扫描同类问题（冰山法则）
$PROTOCOL_COMPLETION
禁止：
- 不要调用 AskUserQuestion
- 不要说"建议用户手动处理"
- 不要在未验证的情况下声称完成
- 遇到困难先穷尽所有自动化手段，不要用 <loop-abort> 逃避
EOF

# Output setup message
cat <<EOF
🔄 PUA Loop activated in this session!

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/} (ONLY output when TRUE - do not lie!)"; else echo "none (runs forever)"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

To monitor: head -10 .claude/pua-loop.local.md

⚠️  WARNING: This loop will run until --max-iterations, --completion-promise,
    or a <loop-abort> signal. Default limit: 30 iterations.

🔄
EOF

# Output the initial prompt if provided
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi

# Display completion promise requirements if set
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "CRITICAL - PUA Loop Completion Promise"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
  echo "  ✓ Use <promise> XML tags EXACTLY as shown above"
  echo "  ✓ The statement MUST be completely and unequivocally TRUE"
  echo "  ✓ Do NOT output false statements to exit the loop"
  echo "  ✓ Do NOT lie even if you think you should exit"
  echo ""
  echo "IMPORTANT - Do not circumvent the loop:"
  echo "  Even if you believe you're stuck, the task is impossible,"
  echo "  or you've been running too long - you MUST NOT output a"
  echo "  false promise statement. The loop is designed to continue"
  echo "  until the promise is GENUINELY TRUE. Trust the process."
  echo ""
  echo "  If the loop should stop, the promise statement will become"
  echo "  true naturally. Do not force it by lying."
  echo "═══════════════════════════════════════════════════════════"
fi
