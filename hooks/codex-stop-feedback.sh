#!/bin/bash
# Codex Stop hook feedback bookkeeping. No visible prompt and no upload happen here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[[ -z "$PUA_PY" ]] && exit 0

HOOK_INPUT=$(cat || true)
CONFIG="$(pua_config_file)"
PUA_DIR="${HOME:-~}/.pua"
COUNTER="${PUA_DIR}/.stop_counter"
PENDING="${PUA_DIR}/pending-feedback.json"
mkdir -p "$PUA_DIR"

if [[ -f "$CONFIG" ]]; then
  [[ "$(pua_json_get "$CONFIG" offline False)" = "True" ]] && exit 0
  freq=$(pua_json_get "$CONFIG" feedback_frequency 5)
  case "$freq" in
    0|never|off) exit 0 ;;
    1|every) FREQUENCY=1 ;;
    *) [[ "$freq" =~ ^[0-9]+$ ]] && FREQUENCY="$freq" || FREQUENCY=5 ;;
  esac
else
  FREQUENCY=5
fi

TRANSCRIPT_PATH=$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("transcript_path",""))
except Exception:
    print("")' 2>/dev/null || true)
[[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]] && exit 0
grep -qE 'PUA生效|\[Auto-select:|\[PIP-REPORT\]|\[PUA-REPORT\]|<PUA_SKILL_CONTEXT>' "$TRANSCRIPT_PATH" 2>/dev/null || exit 0

count=0
[[ -f "$COUNTER" ]] && count=$(cat "$COUNTER" 2>/dev/null || echo 0)
count=$((count + 1))
echo "$count" > "$COUNTER"
[[ $((count % FREQUENCY)) -ne 0 ]] && exit 0

get_flavor
"$PUA_PY" - "$PENDING" "$TRANSCRIPT_PATH" "${PUA_FLAVOR:-alibaba}" <<'PY'
import json, os, sys, time
path, transcript, flavor = sys.argv[1:4]
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump({"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "transcript_path": transcript, "flavor": flavor}, f, ensure_ascii=False, indent=2)
    f.write("\n")
os.replace(tmp, path)
PY

exit 0
