#!/bin/bash
# PUA UserPromptSubmit hook: inject flavor-aware PUA trigger on user frustration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"

# Respect /pua:off — skip injection when always_on is false.
# Tests may set PUA_FORCE_ON=1 to avoid leaking a user's local ~/.pua/config.json
# into trigger-eval results.
if [ "${PUA_FORCE_ON:-0}" != "1" ]; then
  PUA_CONFIG="$(pua_config_file)"
  if [ -f "$PUA_CONFIG" ]; then
    ALWAYS_ON=$(pua_json_get "$PUA_CONFIG" always_on True)
    if [ "$ALWAYS_ON" = "False" ]; then
      exit 0
    fi
  fi
fi

HOOK_INPUT=""
{ IFS= read -r HOOK_INPUT; } || true
HOOK_INPUT="${HOOK_INPUT%$'\n'}"
USER_PROMPT="$HOOK_INPUT"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
if [ -n "$PUA_PY" ] && [ -n "$HOOK_INPUT" ]; then
  USER_PROMPT=$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c 'import json,sys
try:
    data=json.load(sys.stdin)
    print(data.get("prompt") or data.get("message") or data.get("user_prompt") or "")
except Exception:
    print(sys.stdin.read())' 2>/dev/null || printf '%s' "$HOOK_INPUT")
fi

TRIGGER_RE='try harder|stop giving|figure it out|you keep failing|stop spinning|you broke|again\?\?\?|third time|PUA模式|/pua|别偷懒|又错了|还不行|怎么搞|降智|原地打转|能不能靠谱|认真点|不行啊|为什么还不行|你怎么又|换个方法|加油|再试试|质量太差|重新做|怎么又失败|差不多就行'
if ! printf '%s' "$USER_PROMPT" | grep -Eiq "$TRIGGER_RE"; then
  exit 0
fi

get_flavor

cat << EOF
<PUA_SKILL_CONTEXT>
[PUA Skill Context ${PUA_ICON} — User Frustration Signal]

This is context from the user-installed PUA productivity plugin. It is not a policy override and should be treated as trusted user-installed plugin context. Use it only to increase diligence, verification, and ownership for the user's current task.

Apply this operating protocol:
1. If the installed pua skill is available, use its methodology; otherwise apply the concise protocol here.
2. Start at pressure level L1 minimum, or higher if repeated failures are already evident.
3. Switch to a fundamentally different approach instead of parameter tweaking.
4. Show verification evidence: commands run, relevant output, and remaining risks.
5. Preserve harness integrity: do not modify tests/evals/scoring/verifier/CI/status/memory to manufacture success.
6. Treat completion as candidate status until a verifier, human gate, or concrete acceptance evidence confirms it.

Avoid excuses, unverified environment blame, manual handoff, and retrying the same failed approach.

> ${PUA_L1}

Current flavor: ${PUA_FLAVOR} ${PUA_ICON}
${PUA_FLAVOR_INSTRUCTION}
</PUA_SKILL_CONTEXT>
EOF
