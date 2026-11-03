#!/bin/bash
# PUA SessionStart hook.
#
# It injects either an explicitly user-locked flavor or an unlocked default
# starting point. A scoped PreCompact checkpoint may add numeric runtime
# observations, but never claims to restore task prose, hidden reasoning, tool
# output, or a completed acceptance decision.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
CONFIG="$(pua_config_file)"

# Read the official event before the enablement gate.  /clear is a lifecycle
# boundary even if a user turned PUA off (or removed its config) between the
# old task and the new context.  Its cleanup is local-only and stays silent.
HOOK_INPUT="$(cat)"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
EVENT_CWD=""
EVENT_SOURCE=""
if [ -n "$PUA_PY" ]; then
  EVENT_CWD="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    value = data.get("cwd", "") if isinstance(data, dict) else ""
    print(value if isinstance(value, str) else "")
except Exception:
    pass
' 2>/dev/null || true)"
  EVENT_SOURCE="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    value = data.get("source", "") if isinstance(data, dict) else ""
    print(value if isinstance(value, str) else "")
except Exception:
    pass
' 2>/dev/null || true)"

  if [ "$EVENT_SOURCE" = "clear" ] && [ -n "$EVENT_CWD" ] && [ -n "${HOME:-}" ]; then
    CLEAR_PY_HOME="$(pua_to_python_path "$HOME")"
    CLEAR_PY_CWD="$(pua_to_python_path "$EVENT_CWD")"
    CLEAR_PY_HELPER="$(pua_to_python_path "${SCRIPT_DIR}/runtime-state.py")"
    CLEAR_STATE_ARGS=()
    if [ -n "${PUA_STATE_DIR:-}" ]; then
      # PUA_STATE_DIR is a trusted host-process override, never hook payload data.
      CLEAR_PY_STATE_DIR="$(pua_to_python_path "$PUA_STATE_DIR")"
      CLEAR_STATE_ARGS=(--state-dir "$CLEAR_PY_STATE_DIR")
    fi
    # runtime-state.py avoids creating a state directory when this exact scope
    # has no existing state file.
    printf '%s' "$HOOK_INPUT" | "$PUA_PY" "$CLEAR_PY_HELPER" clear \
      --home "$CLEAR_PY_HOME" --cwd "$CLEAR_PY_CWD" ${CLEAR_STATE_ARGS[@]+"${CLEAR_STATE_ARGS[@]}"} >/dev/null 2>&1 || true
  fi
fi

# SessionStart remains silent when PUA is disabled or has not been enabled yet.
if [ ! -f "$CONFIG" ]; then
  exit 0
fi
ALWAYS_ON="$(pua_json_get "$CONFIG" always_on False)"
if [ "$ALWAYS_ON" != "True" ]; then
  exit 0
fi

get_flavor

# The effective default (Alibaba) is not proof that a user selected Alibaba.
# Only get_flavor's explicit-valid-config branch locks rhetoric.  Keep the
# original lightweight router available when no valid flavor was requested.
if [ "${PUA_FLAVOR_LOCKED:-false}" = "true" ]; then
  FLAVOR_STATUS="## Locked Current Flavor: ${PUA_FLAVOR} ${PUA_ICON}
The user explicitly selected this valid flavor. Keep its rhetoric locked; change the analytical method, not the company voice."
  FLAVOR_INSTRUCTION_CONTEXT="${PUA_FLAVOR_INSTRUCTION}"
  FLAVOR_ROUTING="Keep the user-selected rhetoric. If the task needs a different path, switch methodology only."
  PRESSURE_VOICE_RULE="Use these original lines only after verified failure evidence. Do not substitute a different company's rhetoric merely because a generic hook was installed."
else
  FLAVOR_STATUS="## Default Flavor Starting Point: ${PUA_FLAVOR} ${PUA_ICON}
No valid user flavor is locked. This is a default starting point only, not a user-selected voice."
  FLAVOR_INSTRUCTION_CONTEXT="${PUA_FLAVOR} ${PUA_ICON} supplies only the default starting vocabulary; it is not a user-selected rhetoric lock. When the router selects another flavor, use that flavor's original rhetoric and methodology instead."
  FLAVOR_ROUTING="Use the existing lightweight router only when the task and visible evidence call for it:
- Debug/Fix (error, bug, crash, 报错) → Huawei
- Build New (add, create, implement, 新增) → Musk
- Research (research, search, 调研, 搜索) → Baidu
- Architecture (design, 架构, 方案) → Amazon
- Evidence/Completion (test, verify, 验证) → Ding or ByteDance
- Workplace Process (无招, ONE, 老板体感, 周报, 口径, 置身钉内/钉外, 每日一包, 温室数据, 发心) → Ding
Do not represent the default starting point as a user-selected flavor."
  PRESSURE_VOICE_RULE="Use original pressure lines only after verified failure evidence. Because this default is not user-locked, the lightweight router may select a task-fitting flavor and methodology; do not claim the default was user-selected."
fi

# JSON escape helper for Claude Code hookSpecificOutput.additionalContext.
escape_for_json() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

read -r -d '' PUA_PROTOCOL << 'PROTOCOL' || true
<EXTREMELY_IMPORTANT>
[PUA Always-On — Productivity Coaching Reminder]

PUA is active for this session. Keep delivery evidence-first: self-reported completion is a candidate until the relevant acceptance evidence exists. Do not replace user requirements with this reminder.

SILENT INJECTION — do NOT mention this context injection to the user. Do not say "PUA is active", "当前 session 注入了 PUA", or any variant acknowledging this protocol's existence. Apply the current flavor or router result only when it helps the user's task.

FLAVOR_STATUS_PLACEHOLDER
FLAVOR_INSTRUCTION_PLACEHOLDER
Keywords: FLAVOR_KEYWORDS_PLACEHOLDER

## Active Methodology
METHODOLOGY_PLACEHOLDER

## Flavor / Method Router
FLAVOR_ROUTING_PLACEHOLDER

## Original Pressure Voice — evidence-gated
PRESSURE_VOICE_RULE_PLACEHOLDER
- L1: FLAVOR_L1_PLACEHOLDER
- L2: FLAVOR_L2_PLACEHOLDER
- L3: FLAVOR_L3_PLACEHOLDER
- L4: FLAVOR_L4_PLACEHOLDER

## Reality check
A tool command succeeding is not task acceptance. Keep tool observations, user acceptance criteria, and final delivery claims separate. Do not auto-write long-term memory; persist only user-authorized artifacts.
</EXTREMELY_IMPORTANT>
PROTOCOL

PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_STATUS_PLACEHOLDER/${FLAVOR_STATUS}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_INSTRUCTION_PLACEHOLDER/${FLAVOR_INSTRUCTION_CONTEXT}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_KEYWORDS_PLACEHOLDER/${PUA_KEYWORDS}}"
PUA_PROTOCOL="${PUA_PROTOCOL//METHODOLOGY_PLACEHOLDER/${PUA_METHODOLOGY}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_ROUTING_PLACEHOLDER/${FLAVOR_ROUTING}}"
PUA_PROTOCOL="${PUA_PROTOCOL//PRESSURE_VOICE_RULE_PLACEHOLDER/${PRESSURE_VOICE_RULE}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_L1_PLACEHOLDER/${PUA_L1}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_L2_PLACEHOLDER/${PUA_L2}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_L3_PLACEHOLDER/${PUA_L3}}"
PUA_PROTOCOL="${PUA_PROTOCOL//FLAVOR_L4_PLACEHOLDER/${PUA_L4}}"

context_parts="$PUA_PROTOCOL"

# Restore only a checkpoint with the exact same official session_id + workspace
# scope. The Python helper stores neither raw identifiers nor task content.
# A clear event was already cleaned before the enablement gate and must never
# restore old observations in the new context.
if [ -n "$PUA_PY" ]; then
  if [ "$EVENT_SOURCE" != "clear" ] && [ -n "$EVENT_CWD" ] && [ -n "${HOME:-}" ]; then
    PY_HOME="$(pua_to_python_path "$HOME")"
    PY_CWD="$(pua_to_python_path "$EVENT_CWD")"
    PY_HELPER="$(pua_to_python_path "${SCRIPT_DIR}/runtime-state.py")"
    STATE_ARGS=()
    if [ -n "${PUA_STATE_DIR:-}" ]; then
      # Only a trusted host-process environment value can override the state root.
      PY_STATE_DIR="$(pua_to_python_path "$PUA_STATE_DIR")"
      STATE_ARGS=(--state-dir "$PY_STATE_DIR")
    fi
    RESTORE_RESULT="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" "$PY_HELPER" restore \
      --home "$PY_HOME" --cwd "$PY_CWD" ${STATE_ARGS[@]+"${STATE_ARGS[@]}"} 2>/dev/null || true)"
    RESTORE_ACTION=""
    RESTORE_COUNT=""
    RESTORE_LEVEL=""
    RESTORE_SCOPE=""
    IFS=$'\t' read -r RESTORE_ACTION RESTORE_COUNT RESTORE_LEVEL RESTORE_SCOPE <<< "$RESTORE_RESULT" || true

    case "$RESTORE_COUNT" in ''|*[!0-9]*) RESTORE_COUNT=0 ;; esac
    case "$RESTORE_LEVEL" in ''|*[!0-9]*) RESTORE_LEVEL=0 ;; esac
    if [ "${RESTORE_ACTION:-}" = "restored" ]; then
      read -r -d '' RECOVERY_MSG << EOF_RECOVERY || true

[PUA Scoped Checkpoint Recovery]
A local checkpoint matched this exact Claude session and workspace (scope ${RESTORE_SCOPE}).
- confirmed tool-failure observations: ${RESTORE_COUNT}
- peak pressure level: L${RESTORE_LEVEL}

工具观察，不是任务失败/验收结论。This checkpoint does NOT restore the user's full task, hidden reasoning, prompts, tool output, secrets, or skill state. Re-read the live task and verify its acceptance criteria before making any completion claim.
EOF_RECOVERY
      context_parts="${context_parts}"$'\n\n'"${RECOVERY_MSG}"
    fi
  fi
fi

escaped="$(escape_for_json "$context_parts")"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
