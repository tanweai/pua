#!/bin/bash
# Codex command hook replacement for Claude prompt-based PreCompact.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"
PUA_PY="$(pua_python_cmd 2>/dev/null || true)"

HOOK_INPUT=$(cat || true)
PUA_DIR="$(pua_state_dir)"
JOURNAL="${PUA_DIR}/builder-journal.md"
CONFIG="$(pua_config_file)"
mkdir -p "$PUA_DIR"

FAILURE_COUNT=0
[[ -f "$PUA_DIR/.failure_count" ]] && FAILURE_COUNT=$(cat "$PUA_DIR/.failure_count" 2>/dev/null || echo 0)
PEAK_LEVEL=0
[[ -f "$PUA_DIR/.peak_pressure_level" ]] && PEAK_LEVEL=$(cat "$PUA_DIR/.peak_pressure_level" 2>/dev/null || echo 0)

get_flavor
ALWAYS_ON=False
[[ -f "$CONFIG" ]] && ALWAYS_ON=$(pua_json_get "$CONFIG" always_on False)

TRANSCRIPT_PATH=""
TRIGGER="unknown"
if [[ -n "$PUA_PY" ]]; then
  TRANSCRIPT_PATH=$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("transcript_path",""))
except Exception:
    print("")' 2>/dev/null || true)
  TRIGGER=$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("trigger") or d.get("compact_trigger") or d.get("matcher") or "unknown")
except Exception:
    print("unknown")' 2>/dev/null || true)
fi

PUA_MARKERS=0
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  PUA_MARKERS=$(grep -Ec 'PUA生效|\[PUA|\[PIP-REPORT\]|\[PUA-REPORT\]|<PUA_SKILL_CONTEXT>' "$TRANSCRIPT_PATH" 2>/dev/null || echo 0)
fi

if [[ "$ALWAYS_ON" != "True" && "${FAILURE_COUNT:-0}" = "0" && "${PUA_MARKERS:-0}" = "0" ]]; then
  exit 0
fi

cat > "$JOURNAL" <<EOF
# PUA Builder Journal — Codex Compaction Note

## Timestamp
$(date -u +%Y-%m-%dT%H:%M:%SZ)

## Runtime State
- runtime: codex
- compact_trigger: ${TRIGGER}
- pressure_level: L${PEAK_LEVEL:-0}
- failure_count: ${FAILURE_COUNT:-0}
- current_flavor: ${PUA_FLAVOR:-alibaba}
- transcript_markers: ${PUA_MARKERS:-0}

## Next Candidate Action
On resume, restore the current PUA flavor, review failed approaches, and require concrete verification evidence before any completion claim.

## Key Context
- transcript_path: ${TRANSCRIPT_PATH:-unknown}
- config: ${CONFIG}
EOF

"${PUA_PY:-python3}" - "$JOURNAL" <<'PY'
import json, sys
path = sys.argv[1]
print(json.dumps({"hookSpecificOutput":{"hookEventName":"PreCompact","additionalContext":f"[PUA Checkpoint] Local state note saved to {path}"}}, ensure_ascii=False))
PY
