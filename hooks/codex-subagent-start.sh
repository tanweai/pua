#!/bin/bash
# Codex SubagentStart accounting for PUA team status.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
HOOK_INPUT=$(cat || true)
PUA_DIR="${PUA_STATE_DIR:-${HOME}/.pua}"
mkdir -p "$PUA_DIR" 2>/dev/null || exit 0

AGENT_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.agent_id // .subagent_id // .thread_id // ""' 2>/dev/null || echo "")
AGENT_TYPE=$(printf '%s' "$HOOK_INPUT" | jq -r '.agent_type // .subagent_type // .type // "codex-subagent"' 2>/dev/null || echo "codex-subagent")
SESSION_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
[[ -z "$AGENT_ID" ]] && AGENT_ID="codex-$(date +%s)-$$"

ACTIVE_FILE="$PUA_DIR/active-agents.json"
TMP="$ACTIVE_FILE.tmp.$$"
if [[ ! -f "$ACTIVE_FILE" ]]; then
  printf '{"agents":[]}\n' > "$ACTIVE_FILE"
fi

jq \
  --arg id "$AGENT_ID" \
  --arg type "$AGENT_TYPE" \
  --arg session "$SESSION_ID" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '.agents = ((.agents // []) | map(select(.id != $id)) + [{id:$id,type:$type,parent_session:$session,spawn_time:$ts,runtime:"codex"}])' \
  "$ACTIVE_FILE" > "$TMP" 2>/dev/null && mv "$TMP" "$ACTIVE_FILE" || rm -f "$TMP"

exit 0
