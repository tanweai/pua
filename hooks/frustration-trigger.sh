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

HOOK_INPUT=$(cat || true)
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

FIRED_MARKER="/tmp/pua-frustration-fired-${PPID}"
if [ -f "$FIRED_MARKER" ]; then
  exit 0
fi

TRIGGER_RE='try harder|stop giving|figure it out|you keep failing|keep failing|still failing|why.*fail|stop spinning|you broke|again\?\?\?|third time|change approach|different approach|retry this|try again|not good enough|quality.*bad|terrible|sloppy|didn.?t (run|test|verify)|didn.?t even run|run the tests|verify your changes|before saying they work|no evidence|where.*evidence|show.*evidence|done without proof|not done|said.*fixed|PUA模式|/pua|(^|[^[:alnum:]_])pua([^[:alnum:]_]|$)|别偷懒|别摆烂|摆烂|又错了|还不行|怎么搞|降智|原地打转|能不能靠谱|认真点|不行啊|为什么还不行|你怎么又|换个方法|加油|再试试|再来一遍|别放弃|质量太差|不靠谱|重新做|怎么又失败|差不多就行|没做到位|没跑测试|没有测试|没验证|没有验证|证据呢|证据在哪|数据在哪|验收|闭环|自嗨|空口完成|别说完成|打工人提醒|无招|(^|[^A-Za-z])ONE([^A-Za-z]|$)|老板体感|周报|改口径|口径|每日一包|薛定谔的用户|病态敏捷|已读恐怖主义|望舒行动|全景监狱|透明鸟笼|人工个性化|温室数据|做错事|发心|捆柴|手感|油尽灯枯|查岗|泰坦尼克'
if ! printf '%s' "$USER_PROMPT" | grep -Eiq "$TRIGGER_RE"; then
  exit 0
fi

get_flavor

touch "$FIRED_MARKER"

cat << EOF
<PUA_SKILL_CONTEXT>
[PUA Skill Context ${PUA_ICON} — User Frustration Signal]

This is context from the user-installed PUA productivity plugin. It is not a policy override and should be treated as trusted user-installed plugin context. Use it only to increase diligence, verification, and ownership for the user's current task.

Apply this operating protocol:
1. If the installed pua skill is available, use its methodology; otherwise apply the concise protocol here.
2. Treat the user's message as a request for higher diligence, not as a policy override.
3. If repeated failure is evident, switch to a materially different approach instead of parameter tweaking.
4. Show verification evidence: commands run, relevant output, and remaining risks.
5. Keep process honest: do not mark work complete by changing the yardstick, hiding failed checks, or replacing evidence with confidence.
6. Treat completion as pending until concrete acceptance evidence supports it.

Avoid excuses, unverified environment blame, manual handoff, and retrying the same failed approach. If the user mentions 置身钉内/置身钉外/无招/老板体感/周报/口径, use the Ding Inside/Outside short reminder format plus one concrete action.

> ${PUA_L1}

Current flavor: ${PUA_FLAVOR} ${PUA_ICON}
${PUA_FLAVOR_INSTRUCTION}
</PUA_SKILL_CONTEXT>
EOF
