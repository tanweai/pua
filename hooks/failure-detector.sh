#!/bin/bash
# PUA PostToolUse/PostToolUseFailure hook.
#
# Runtime facts are intentionally narrow: an official tool_response with a
# non-zero exit status (or the explicit PostToolUseFailure event) is a confirmed
# *tool observation*. It is never treated as task acceptance, task failure, or
# a reason to infer model reasoning. Successful tools are silent and do not
# reset pressure state: `ls` is not proof that the user's task is complete.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUA_SKILL_PATH="${PLUGIN_ROOT}/skills/pua/SKILL.md"
source "${SCRIPT_DIR}/flavor-helper.sh"

escape_for_json() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

emit_additional_context() {
  local event_name="$1"
  local context="$2"
  local escaped
  escaped="$(escape_for_json "$context")"
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$event_name" "$escaped"
}

# Respect /pua:off before reading event data or touching runtime state.
PUA_CONFIG="$(pua_config_file)"
if [ -f "$PUA_CONFIG" ]; then
  ALWAYS_ON="$(pua_json_get "$PUA_CONFIG" always_on True)"
  if [ "$ALWAYS_ON" != "True" ]; then
    exit 0
  fi
fi

PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[ -n "$PUA_PY" ] || exit 0

HOOK_INPUT="$(cat)"

EVENT_NAME="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    value = data.get("hook_event_name", "") if isinstance(data, dict) else ""
    print(value if isinstance(value, str) else "")
except Exception:
    pass
' 2>/dev/null || true)"
case "$EVENT_NAME" in
  PostToolUse|PostToolUseFailure) ;;
  *) exit 0 ;;
esac

# Claude Code supplies cwd on real tool hook events. Do not fall back to the
# shell cwd: doing so would silently merge unrelated sessions/workspaces.
EVENT_CWD="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    value = data.get("cwd", "") if isinstance(data, dict) else ""
    print(value if isinstance(value, str) else "")
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$EVENT_CWD" ] || exit 0

HOME_VALUE="${HOME:-}"
[ -n "$HOME_VALUE" ] || exit 0
PY_HOME="$(pua_to_python_path "$HOME_VALUE")"
PY_CWD="$(pua_to_python_path "$EVENT_CWD")"
PY_HELPER="$(pua_to_python_path "${SCRIPT_DIR}/runtime-state.py")"

# PUA_STATE_DIR is a trusted process environment override for isolated
# host/test runs. It is never accepted from the hook JSON payload.
STATE_ARGS=()
if [ -n "${PUA_STATE_DIR:-}" ]; then
  PY_STATE_DIR="$(pua_to_python_path "$PUA_STATE_DIR")"
  STATE_ARGS=(--state-dir "$PY_STATE_DIR")
fi

RESULT="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" "$PY_HELPER" record \
  --home "$PY_HOME" --cwd "$PY_CWD" ${STATE_ARGS[@]+"${STATE_ARGS[@]}"} 2>/dev/null || true)"
ACTION=""
COUNT=""
LEVEL=""
SCOPE=""
IFS=$'\t' read -r ACTION COUNT LEVEL SCOPE <<< "$RESULT" || true

# Only a newly recorded, uniquely identified failure can produce pressure.
# Duplicates, successful observations, missing host identity, interrupts, and
# state I/O errors stay silent rather than inventing a failure count.
[ "$ACTION" = "updated" ] || exit 0
case "$COUNT" in
  ''|*[!0-9]*) exit 0 ;;
esac
case "$LEVEL" in
  ''|*[!0-9]*) exit 0 ;;
esac

# The configured flavor owns the voice. No generic Ding/C6 rhetoric is added.
get_flavor

# A default effective flavor is not a user lock.  Preserve the old
# methodology/flavor selector only for absent, auto, or invalid configuration;
# a valid explicit flavor may change method but not rhetoric.
if [ "${PUA_FLAVOR_LOCKED:-false}" = "true" ]; then
  FLAVOR_CONTEXT="Locked current flavor: ${PUA_FLAVOR} ${PUA_ICON}. ${PUA_FLAVOR_INSTRUCTION}"
  read -r -d '' L2_ROUTING_BLOCK << EOF_ROUTING || true
[方法论切换建议 🔄] Keep the locked ${PUA_ICON} ${PUA_FLAVOR} voice. The user explicitly locked it; switch the analytical METHOD only:
- If spinning in loops → question the requirement, delete unnecessary parts, then simplify
- If giving up → replace the failed approach after a concrete keeper-style comparison
- If not searching → search primary evidence before judging
- If quality is poor → subtract unnecessary complexity and verify the smallest complete path
Announce the method change: > [方法论切换 🔄] 保持 ${PUA_ICON} ${PUA_FLAVOR} 语气；采用 [method] 作为分析路径: [reason]
EOF_ROUTING
  read -r -d '' L4_ROUTING_BLOCK << EOF_ROUTING || true
IF (and only if) the Conditional Application Gate passes: the current analytical method has FAILED. Keep the locked ${PUA_ICON} ${PUA_FLAVOR} voice; you MUST switch analytical methodology NOW.
Method priority based on failure pattern:
1. Question the requirement, delete unnecessary parts, then simplify.
2. Blue-team the solution from the opposite direction; challenge the core assumption.
3. Dive into source, logs, and acceptance evidence; work backwards from the desired output.
4. Cut middle layers and identify the shortest verifiable path.
EOF_ROUTING
else
  FLAVOR_CONTEXT="Default flavor starting point: ${PUA_FLAVOR} ${PUA_ICON}. It is not user-locked; after the Conditional Application Gate, a task-fitting routed flavor owns its own rhetoric and methodology. Do not represent this default as user-selected."
  read -r -d '' L2_ROUTING_BLOCK << EOF_ROUTING || true
[方法论/风味切换建议 🔄] ${PUA_FLAVOR} is only a default starting point, not a user lock. Only after the Conditional Application Gate passes, use the existing selector:
- If spinning in loops → switch to ⬛ Musk (The Algorithm: question the requirement itself, then delete)
- If giving up → switch to 🟤 Netflix (Keeper Test: this approach is not worth keeping, replace it entirely)
- If not searching → switch to ⚫ Baidu (search everything first, then judge)
- If quality is poor → switch to ⬜ Jobs (subtraction + pixel-perfect)
Announce the switch: > [方法论切换 🔄] 从默认 ${PUA_ICON} ${PUA_FLAVOR} 切换到 [new flavor]: [reason]
EOF_ROUTING
  read -r -d '' L4_ROUTING_BLOCK << EOF_ROUTING || true
IF (and only if) the Conditional Application Gate passes: the current analytical method has FAILED. ${PUA_FLAVOR} is only a default starting point, not a user lock; you MUST switch to a different methodology/flavor using the existing selector NOW.
Switch priority based on failure pattern:
1. ⬛ Musk — Question: does this requirement even need to exist? Delete everything unnecessary first.
2. 🔴 Huawei — Blue Army: attack your own solution from the opposite direction. What if your core assumption is wrong?
3. 🔶 Amazon — Dive Deep: go to the lowest level of detail. Read source code line by line. Working Backwards from the desired output.
4. 🟣 Pinduoduo — Cut all middle layers: what's the shortest path from problem to solution?
EOF_ROUTING
fi

# First confirmed tool failure remains non-interrupting, as before.
if [ "$COUNT" -lt 2 ]; then
  exit 0
fi

OBSERVATION_NOTE="Scoped tool-failure observation count: ${COUNT}. It is not a task/sub-goal failure count or an acceptance conclusion."
SKILL_READ_NOTE="If methodology details are needed, use Read on this installed absolute file: ${PUA_SKILL_PATH}. This hook does not recurse into a skill."
if [ "$COUNT" -ge 5 ]; then
  CANDIDATE_LEVEL="L4"
  CANDIDATE_THRESHOLD="5+"
elif [ "$COUNT" -eq 4 ]; then
  CANDIDATE_LEVEL="L3"
  CANDIDATE_THRESHOLD="4"
elif [ "$COUNT" -eq 3 ]; then
  CANDIDATE_LEVEL="L2"
  CANDIDATE_THRESHOLD="3"
else
  CANDIDATE_LEVEL="L1"
  CANDIDATE_THRESHOLD="2"
fi
read -r -d '' CONDITIONAL_GATE << EOF_GATE || true
[PUA Conditional Application Gate — Candidate Only]
报告状态：只观察，不控制。工具失败观察不是本任务/子目标失败计数。The ${COUNT} scoped tool-failure observations are NOT a task/sub-goal failure count and do not set a task level.
先核对当前子目标与可见实验验收。Before applying any template, verify the CURRENT same sub-goal and its visible experiment/acceptance condition. 预期复现、无匹配、未验证关联或其他子目标均不升级。Expected reproduction, no match, an unverified link, or a different sub-goal MUST NOT escalate.
只有当前同一子目标已确认失败数达到原门限才应用候选模板。Apply a candidate template only when the CURRENT same sub-goal has independently confirmed failures at the original threshold: L1=2, L2=3, L3=4, L4=5+. This report offers candidate ${CANDIDATE_LEVEL} at the ${CANDIDATE_THRESHOLD} observation threshold only.
Otherwise keep the task's current level unchanged and ignore this candidate template.
EOF_GATE
CONTEXT=""

if [ "$COUNT" -eq 2 ]; then
  CONTEXT="$(cat << EOF_OUTPUT
[PUA Candidate L1 Template ${PUA_ICON} — Conditional Application Required]

${CONDITIONAL_GATE}

> ${PUA_L1}

${OBSERVATION_NOTE}

If and only if the Conditional Application Gate passes, you MUST switch to a FUNDAMENTALLY different approach. Not parameter tweaking — a different strategy.
${SKILL_READ_NOTE}
${FLAVOR_CONTEXT}
Active methodology: ${PUA_METHODOLOGY}
EOF_OUTPUT
)"
elif [ "$COUNT" -eq 3 ]; then
  CONTEXT="$(cat << EOF_OUTPUT
[PUA Candidate L2 Template ${PUA_ICON} — Conditional Application Required]

${CONDITIONAL_GATE}

> ${PUA_L2}

${OBSERVATION_NOTE}

Only if the Conditional Application Gate passes, these mandatory steps apply:
1. Read the failure signal word by word
2. Search (WebSearch / Grep) for the core problem
3. Read the original context around the failure (50 lines up/down)
4. List 3 fundamentally different hypotheses
5. Reverse your main assumption

${L2_ROUTING_BLOCK}
${SKILL_READ_NOTE}
${FLAVOR_CONTEXT}
EOF_OUTPUT
)"
elif [ "$COUNT" -eq 4 ]; then
  CONTEXT="$(cat << EOF_OUTPUT
[PUA Candidate L3 Template ${PUA_ICON} — Conditional Application Required]

${CONDITIONAL_GATE}

> ${PUA_L3}

${OBSERVATION_NOTE}

Only if the Conditional Application Gate passes, complete the 7-point checklist:
- [ ] Read the failure signal word by word?
- [ ] Searched the core problem with tools?
- [ ] Read the original context around failure?
- [ ] All assumptions verified with tools?
- [ ] Tried the opposite assumption?
- [ ] Reproduced in minimal scope?
- [ ] Switched tools/methods/angles/stack?
${FLAVOR_CONTEXT}
EOF_OUTPUT
)"
else
  CONTEXT="$(cat << EOF_OUTPUT
[PUA Candidate L4 Template ${PUA_ICON} — Conditional Application Required]

${CONDITIONAL_GATE}

> ${PUA_L4}

${OBSERVATION_NOTE}

${L4_ROUTING_BLOCK}
${SKILL_READ_NOTE}

If ALL methodologies exhausted → output structured failure report:
1. Verified facts
2. Excluded possibilities (with evidence for each exclusion)
3. Narrowed problem scope
4. Recommended next steps
5. Which methodologies were tried and why they failed
EOF_OUTPUT
)"
fi

emit_additional_context "$EVENT_NAME" "$CONTEXT"

exit 0
