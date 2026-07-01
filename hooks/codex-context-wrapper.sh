#!/bin/bash
# Wrap legacy text-producing PUA hooks as Codex additionalContext JSON.
set -uo pipefail

HOOK_EVENT="${1:-}"
shift || true

if [[ -z "$HOOK_EVENT" || $# -eq 0 ]]; then
  exit 0
fi

HOOK_INPUT=$(cat || true)
set +e
OUTPUT=$(printf '%s' "$HOOK_INPUT" | "$@" 2>/dev/null)
STATUS=$?
set -e

if [[ $STATUS -ne 0 || -z "$OUTPUT" ]]; then
  exit 0
fi

if printf '%s' "$OUTPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); raise SystemExit(0 if isinstance(data,dict) and ("hookSpecificOutput" in data or "decision" in data) else 1)' >/dev/null 2>&1; then
  printf '%s\n' "$OUTPUT"
  exit 0
fi

python3 - "$HOOK_EVENT" "$OUTPUT" <<'PY'
import json, sys
event, text = sys.argv[1], sys.argv[2]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": event,
        "additionalContext": text,
    }
}, ensure_ascii=False))
PY
