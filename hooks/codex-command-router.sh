#!/bin/bash
# Codex UserPromptSubmit router for /pua:* and pending feedback replies.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"

PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[[ -z "$PUA_PY" ]] && exit 0

HOOK_INPUT=$(cat || true)
PROMPT=$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c 'import json,sys
try:
    data=json.load(sys.stdin)
    print(data.get("prompt") or data.get("message") or data.get("user_prompt") or "")
except Exception:
    print(sys.stdin.read())' 2>/dev/null || true)

json_context() {
  "$PUA_PY" - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":sys.argv[1]}}, ensure_ascii=False))
PY
}

update_config() {
  local mode="$1"
  local value="${2:-}"
  local config
  config="$(pua_config_file)"
  mkdir -p "$(dirname "$config")"
  "$PUA_PY" - "$config" "$mode" "$value" <<'PY'
import json, os, sys
path, mode, value = sys.argv[1:4]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    data = {}

if mode == "on":
    data["always_on"] = True
    if str(data.get("feedback_frequency", "")).lower() in {"0", "off", "never"}:
        data["feedback_frequency"] = 5
elif mode == "off":
    data["always_on"] = False
    data["feedback_frequency"] = 0
elif mode == "offline":
    data["offline"] = True
    data["feedback_frequency"] = 0
elif mode == "flavor" and value:
    data["flavor"] = value

tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
os.replace(tmp, path)
PY
}

handle_feedback_reply() {
  local pending="${HOME:-~}/.pua/pending-feedback.json"
  [[ ! -f "$pending" ]] && return 1
  case "$PROMPT" in
    *"pua feedback skip"*|*"这次跳过"*|*"跳过"*|*"skip"*)
      mkdir -p "${HOME:-~}/.pua"
      printf '{"ts":"%s","rating":"skip","uploaded":false}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${HOME:-~}/.pua/feedback.jsonl"
      rm -f "$pending"
      json_context "[PUA Feedback] Skipped and recorded locally. Continue the user's task normally."
      return 0
      ;;
    *"pua feedback useful upload"*|*"上传评分 + 脱敏 session"*|*"上传脱敏"*|*"upload session"*)
      bash "${SCRIPT_DIR}/codex-feedback-submit.sh" useful_upload
      return 0
      ;;
    *"pua feedback useful"*|*"很有用"*|*"useful"*)
      bash "${SCRIPT_DIR}/codex-feedback-submit.sh" useful
      return 0
      ;;
    *"pua feedback ok"*|*"一般般"*|*"ok"*)
      bash "${SCRIPT_DIR}/codex-feedback-submit.sh" ok
      return 0
      ;;
  esac
  return 1
}

handle_feedback_reply && exit 0

COMMAND=$("$PUA_PY" - "$PROMPT" <<'PY'
import re, sys
prompt = sys.argv[1].strip()
patterns = [
    r"^/pua(?::(?P<cmd>[A-Za-z0-9_-]+))?(?:\s+(?P<rest>.*))?$",
    r"^/pua\s+(?P<cmd2>[A-Za-z0-9_-]+)(?:\s+(?P<rest2>.*))?$",
]
for pat in patterns:
    m = re.match(pat, prompt)
    if m:
        cmd = m.groupdict().get("cmd") or m.groupdict().get("cmd2") or "pua"
        rest = m.groupdict().get("rest") if m.groupdict().get("rest") is not None else m.groupdict().get("rest2") or ""
        if cmd == "pua" and rest:
            first, _, tail = rest.partition(" ")
            if first in {"pua","p7","p9","p10","pro","yes","mama","shot","pua-loop","loop","on","off","offline","survey","flavor","kpi","cancel-pua-loop","cancel-loop","team-status","reap-orphans","teardown-all","pua-en","pua-ja","en","ja"}:
                cmd, rest = first, tail
        print(cmd + "\t" + rest)
        break
PY
)

[[ -z "$COMMAND" ]] && exit 0

CMD="${COMMAND%%	*}"
REST="${COMMAND#*	}"

case "$CMD" in
  loop) CMD="pua-loop" ;;
  cancel-loop) CMD="cancel-pua-loop" ;;
  en) CMD="pua-en" ;;
  ja) CMD="pua-ja" ;;
esac

case "$CMD" in
  on)
    update_config on
    json_context "[PUA ON] Always-on mode enabled for Codex. Future sessions will receive PUA SessionStart context."
    ;;
  off)
    update_config off
    json_context "[PUA OFF] Always-on mode and feedback prompts disabled for Codex."
    ;;
  offline)
    update_config offline
    json_context "[PUA OFFLINE] Offline mode enabled. Local PUA behavior stays on; feedback, upload, leaderboard, and heartbeat network flows stay off."
    ;;
  flavor)
    if [[ -n "$REST" ]]; then
      update_config flavor "$REST"
      json_context "[PUA Flavor] Flavor set to ${REST}. Preserve this flavor in PUA reminders."
    else
      json_context "User invoked /pua:flavor. Use the \$pua-flavor skill to show the 14 corporate flavors and help choose one."
    fi
    ;;
  pua-loop)
    if [[ -z "$REST" ]]; then
      json_context "User invoked /pua:pua-loop without arguments. Ask for the loop task, optional --verify command, and optional --completion-promise."
      exit 0
    fi
    LOOP_OUTPUT=$(PUA_PLUGIN_ROOT="$PLUGIN_ROOT" "$PUA_PY" - "$REST" "$PLUGIN_ROOT/scripts/setup-pua-loop.sh" <<'PY'
import os, shlex, subprocess, sys
rest, script = sys.argv[1], sys.argv[2]
try:
    args = shlex.split(rest)
except ValueError as exc:
    print(f"[PUA Loop] Could not parse arguments: {exc}")
    raise SystemExit(0)
env = os.environ.copy()
env.setdefault("PUA_RUNTIME", "codex")
proc = subprocess.run(["bash", script, *args], text=True, capture_output=True, env=env)
out = (proc.stdout + ("\n" + proc.stderr if proc.stderr else "")).strip()
print(out)
PY
)
    json_context "${LOOP_OUTPUT:-[PUA Loop] Activated. Continue the loop task under the PUA Loop protocol.}"
    ;;
  pua|p7|p9|p10|pro|yes|mama|shot|pua-en|pua-ja|survey|kpi|team-status|reap-orphans|teardown-all|cancel-pua-loop)
    SKILL="$CMD"
    case "$CMD" in
      pua) SKILL="pua" ;;
      p7|p9|p10|pro|yes|mama) SKILL="pua-$CMD" ;;
      shot) SKILL="pua-shot" ;;
      pua-en|pua-ja) SKILL="$CMD" ;;
      cancel-pua-loop) SKILL="pua-cancel-pua-loop" ;;
      *) SKILL="pua-$CMD" ;;
    esac
    json_context "User invoked /pua:${CMD}. Use the \$${SKILL} Codex skill semantics for this turn. Arguments: ${REST:-none}"
    ;;
  *)
    json_context "User invoked /pua:${CMD}. Route through \$pua if no narrower PUA Codex skill exists. Arguments: ${REST:-none}"
    ;;
esac
