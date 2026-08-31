#!/bin/bash
# Stop hooks run concurrently in Codex. Keep PUA Loop before feedback in one dispatcher.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_INPUT=$(cat || true)

set +e
LOOP_OUTPUT=$(printf '%s' "$HOOK_INPUT" | PUA_RUNTIME=codex bash "${SCRIPT_DIR}/pua-loop-hook.sh" 2>/dev/null)
LOOP_STATUS=$?
set -e

if [[ $LOOP_STATUS -eq 0 && -n "$LOOP_OUTPUT" ]]; then
  if printf '%s' "$LOOP_OUTPUT" | python3 -c 'import json,sys; data=json.load(sys.stdin); raise SystemExit(0 if data.get("decision")=="block" else 1)' >/dev/null 2>&1; then
    printf '%s\n' "$LOOP_OUTPUT"
    exit 0
  fi
fi

printf '%s' "$HOOK_INPUT" | PUA_RUNTIME=codex bash "${SCRIPT_DIR}/codex-stop-feedback.sh"
