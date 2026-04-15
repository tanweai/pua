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
