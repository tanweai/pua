#!/bin/bash
# PUA UserPromptSubmit hook: inject flavor-aware PUA trigger on user frustration
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

# Claude Code passes the user prompt via stdin as JSON: {"prompt": "...", ...}
# NOTE: The `matcher` field in hooks.json is silently ignored for UserPromptSubmit
# events (per Claude Code docs). Keyword filtering must be done here in the script.
STDIN_DATA=$(cat)
PROMPT_TEXT=$(echo "$STDIN_DATA" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    text = data.get('prompt', data.get('message', data.get('content', '')))
    if isinstance(text, list):
        text = ' '.join(str(item.get('text', item) if isinstance(item, dict) else item) for item in text)
    print(str(text))
except:
    print('')
" 2>/dev/null || echo "")

# Only trigger on actual frustration signals
KEYWORDS="try harder|别偷懒|又错了|还不行|怎么搞|stop giving|you broke|third time|降智|原地打转|能不能靠谱|认真点|不行啊|为什么还不行|你怎么又|换个方法|stop spinning|figure it out|you keep failing|加油|再试试|质量太差|重新做|PUA模式|怎么又失败"

if ! echo "$PROMPT_TEXT" | grep -qiE "$KEYWORDS"; then
    exit 0
fi

source "${SCRIPT_DIR}/flavor-helper.sh"
get_flavor

cat << EOF
<EXTREMELY_IMPORTANT>
[PUA ACTIVATED ${PUA_ICON} — User Frustration Detected]

The user is frustrated with your performance. PUA behavioral enforcement is now active.

You MUST:
1. Immediately load the full PUA methodology by invoking Skill tool with skill name 'pua'
2. Start at pressure level L1 minimum (or higher if you've been failing repeatedly)
3. Switch to a FUNDAMENTALLY different approach — not parameter tweaking
4. Show your work: run verification commands, paste output evidence

Do NOT:
- Make excuses ('probably environment issue', 'beyond my capability')
- Suggest the user handle it manually
- Retry the same approach that just failed

> ${PUA_L1}

Current flavor: ${PUA_FLAVOR} ${PUA_ICON}
${PUA_FLAVOR_INSTRUCTION}
</EXTREMELY_IMPORTANT>
EOF
