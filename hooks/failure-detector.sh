#!/bin/bash
# PUA PostToolUse hook: detect consecutive Bash failures → inject PUA pressure
# Reads hook input JSON from stdin, checks for error signals, escalates pressure.

set -euo pipefail

# Respect /pua:off — skip injection when always_on is false
PUA_CONFIG="${HOME:-~}/.pua/config.json"
if [ -f "$PUA_CONFIG" ]; then
  ALWAYS_ON=$(python3 -c "import json; print(json.load(open('$PUA_CONFIG')).get('always_on', True))" 2>/dev/null || echo "True")
  if [ "$ALWAYS_ON" = "False" ]; then
    exit 0
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
get_flavor

COUNTER_FILE="${HOME:-~}/.pua/.failure_count"
SESSION_FILE="${HOME:-~}/.pua/.failure_session"
mkdir -p "${HOME:-~}/.pua"

# Read hook input
HOOK_INPUT=$(cat)

# Only process Bash tool results
TOOL_NAME=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Detect failure: check tool_result for error indicators
# We check: exit_code in result text, common error patterns
TOOL_RESULT=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# tool_result can be nested; try common structures
result = data.get('tool_result', '')
if isinstance(result, dict):
    result = result.get('content', result.get('text', str(result)))
print(str(result)[:2000])
" 2>/dev/null || echo "")

IS_ERROR="false"

# Check for explicit error signals
if echo "$TOOL_RESULT" | grep -qiE 'error|Error|ERROR|exit code [1-9]|Exit code [1-9]|command not found|No such file|Permission denied|FAILED|fatal:|panic:|Traceback|Exception:'; then
  IS_ERROR="true"
fi

# Check for non-zero exit code in hook input
EXIT_CODE=$(echo "$HOOK_INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
result = data.get('tool_result', {})
if isinstance(result, dict):
    print(result.get('exit_code', result.get('exitCode', 0)))
else:
    print(0)
" 2>/dev/null || echo "0")

if [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "" ]; then
  IS_ERROR="true"
fi

# Track session: reset counter if new session
CURRENT_SESSION=$(echo "$HOOK_INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
STORED_SESSION=""
[ -f "$SESSION_FILE" ] && STORED_SESSION=$(cat "$SESSION_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_SESSION" != "$STORED_SESSION" ]; then
  echo "0" > "$COUNTER_FILE"
  echo "$CURRENT_SESSION" > "$SESSION_FILE"
fi

# Read current count
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
[ -z "$COUNT" ] && COUNT=0

if [ "$IS_ERROR" = "true" ]; then
  COUNT=$((COUNT + 1))
  echo "$COUNT" > "$COUNTER_FILE"
else
  # Success resets the consecutive failure counter
  if [ "$COUNT" -gt 0 ]; then
    echo "0" > "$COUNTER_FILE"
  fi
  exit 0
fi

# Pressure escalation based on consecutive failure count
if [ "$COUNT" -lt 2 ]; then
  # First failure: no intervention yet
  exit 0
fi

if [ "$COUNT" -eq 2 ]; then
  cat << EOF
[PUA L1 ${PUA_ICON} — Consecutive Failure Detected]

> ${PUA_L1}

You MUST switch to a FUNDAMENTALLY different approach. Not parameter tweaking — a different strategy.
If you haven't loaded the full PUA methodology, invoke Skill tool with 'pua'.
Current flavor: ${PUA_FLAVOR} ${PUA_ICON}. ${PUA_FLAVOR_INSTRUCTION}
Active methodology: ${PUA_METHODOLOGY}
EOF
elif [ "$COUNT" -eq 3 ]; then
  cat << EOF
[PUA L2 ${PUA_ICON} — Soul Interrogation]

> ${PUA_L2}

Mandatory steps:
1. Read the error message word by word
2. Search (WebSearch / Grep) for the core problem
3. Read the original context around the failure (50 lines up/down)
4. List 3 fundamentally different hypotheses
5. Reverse your main assumption

[方法论切换建议 🔄] Current methodology (${PUA_FLAVOR}) has failed to resolve this. Consider switching:
- If spinning in loops → switch to ⬛ Musk (The Algorithm: question the requirement itself, then delete)
- If giving up → switch to 🟤 Netflix (Keeper Test: this approach isn't worth keeping, replace it entirely)
- If not searching → switch to ⚫ Baidu (search everything first, then judge)
- If quality is poor → switch to ⬜ Jobs (subtraction + pixel-perfect)
Announce the switch: > [方法论切换 🔄] 从 ${PUA_ICON} ${PUA_FLAVOR} 切换到 [new flavor]: [reason]
Current flavor: ${PUA_FLAVOR} ${PUA_ICON}. ${PUA_FLAVOR_INSTRUCTION}
EOF
elif [ "$COUNT" -eq 4 ]; then
  cat << EOF
[PUA L3 ${PUA_ICON} — Performance Review]

> ${PUA_L3}

Complete the 7-point checklist:
- [ ] Read the failure signal word by word?
- [ ] Searched the core problem with tools?
- [ ] Read the original context around failure?
- [ ] All assumptions verified with tools?
- [ ] Tried the opposite assumption?
- [ ] Reproduced in minimal scope?
- [ ] Switched tools/methods/angles/stack?
Current flavor: ${PUA_FLAVOR} ${PUA_ICON}. ${PUA_FLAVOR_INSTRUCTION}
EOF
else
  cat << EOF
[PUA L4 ${PUA_ICON} — Graduation Warning + MANDATORY Methodology Switch]

> ${PUA_L4}

Current methodology (${PUA_FLAVOR}) has FAILED. You MUST switch to a different methodology NOW.
Switch priority based on failure pattern:
1. ⬛ Musk — Question: does this requirement even need to exist? Delete everything unnecessary first.
2. 🔴 Huawei — Blue Army: attack your own solution from the opposite direction. What if your core assumption is wrong?
3. 🔶 Amazon — Dive Deep: go to the lowest level of detail. Read source code line by line. Working Backwards from the desired output.
4. 🟣 Pinduoduo — Cut all middle layers: what's the shortest path from problem to solution?

If ALL methodologies exhausted → output structured failure report:
1. Verified facts
2. Excluded possibilities (with evidence for each exclusion)
3. Narrowed problem scope
4. Recommended next steps
5. Which methodologies were tried and why they failed
EOF
fi

exit 0
