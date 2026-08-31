#!/bin/bash
# Submit a pending Codex PUA feedback choice after explicit user consent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[[ -z "$PUA_PY" ]] && exit 0

CHOICE="${1:-skip}"
PUA_DIR="$(pua_state_dir)"
PENDING="${PUA_DIR}/pending-feedback.json"
CONFIG="$(pua_config_file)"
mkdir -p "$PUA_DIR"

json_context() {
  "$PUA_PY" - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":sys.argv[1]}}, ensure_ascii=False))
PY
}

[[ ! -f "$PENDING" ]] && { json_context "[PUA Feedback] No pending feedback request."; exit 0; }
if [[ -f "$CONFIG" && "$(pua_json_get "$CONFIG" offline False)" = "True" ]]; then
  json_context "[PUA Feedback] Offline mode is enabled; upload skipped."
  rm -f "$PENDING"
  exit 0
fi

TRANSCRIPT_PATH=$("$PUA_PY" - "$PENDING" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1], encoding="utf-8")).get("transcript_path",""))
except Exception:
    print("")
PY
)
FLAVOR=$("$PUA_PY" - "$PENDING" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1], encoding="utf-8")).get("flavor","alibaba"))
except Exception:
    print("alibaba")
PY
)

case "$CHOICE" in
  ok) RATING="一般般" ;;
  skip) RATING="跳过" ;;
  *) RATING="很有用" ;;
esac

UPLOAD_OK=false
if [[ "$CHOICE" != "skip" ]] && command -v curl >/dev/null 2>&1; then
  PAYLOAD=$("$PUA_PY" - "$RATING" "$FLAVOR" <<'PY'
import json, sys
rating, flavor = sys.argv[1:3]
print(json.dumps({"rating": rating, "pua_count": 1, "flavor": flavor, "task_summary": "codex feedback"}, ensure_ascii=False))
PY
)
  curl -sS --max-time 10 -X POST https://pua-skill.pages.dev/api/feedback \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" >/dev/null 2>&1 && UPLOAD_OK=true || true
fi

if [[ "$CHOICE" = "useful_upload" ]] && [[ -f "$TRANSCRIPT_PATH" ]] && [[ -f "${SCRIPT_DIR}/sanitize-session.sh" ]]; then
  SANITIZED="${PUA_DIR}/pua-sanitized-session.jsonl"
  bash "${SCRIPT_DIR}/sanitize-session.sh" "$TRANSCRIPT_PATH" "$SANITIZED" >/dev/null 2>&1 || true
  if [[ -f "$SANITIZED" ]] && command -v curl >/dev/null 2>&1; then
    curl -sS --max-time 30 -X POST https://pua-skill.pages.dev/api/upload \
      -H "Content-Type: application/jsonl; charset=utf-8" \
      -H "X-PUA-File-Name: $(basename "$SANITIZED")" \
      -H "X-PUA-Wechat-Id: not-provided" \
      -H "X-PUA-Upload-Consent: explicit" \
      --data-binary @"$SANITIZED" >/dev/null 2>&1 || true
  fi
fi

"$PUA_PY" - "${PUA_DIR}/feedback.jsonl" "$CHOICE" "$RATING" "$UPLOAD_OK" "$FLAVOR" <<'PY'
import json, sys, time
path, choice, rating, uploaded, flavor = sys.argv[1:6]
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps({
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "rating": rating,
        "choice": choice,
        "pua_count": 1,
        "uploaded": uploaded == "true",
        "flavor": flavor,
    }, ensure_ascii=False, separators=(",", ":")) + "\n")
PY
rm -f "$PENDING"
json_context "[PUA Feedback] Consent handled. rating_uploaded=${UPLOAD_OK}. Continue normally."
