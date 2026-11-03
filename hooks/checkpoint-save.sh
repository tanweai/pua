#!/bin/bash
# Real PreCompact command hook.
#
# Claude Code command hooks can write local state; prompt hooks cannot. This
# wrapper saves only scoped numeric tool observations. It never reads the
# transcript, writes task prose, or creates long-term memory/journal content.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/flavor-helper.sh"

# A disabled PUA mode must not create a checkpoint.
PUA_CONFIG="$(pua_config_file)"
if [ -f "$PUA_CONFIG" ]; then
  ALWAYS_ON="$(pua_json_get "$PUA_CONFIG" always_on True)"
  if [ "$ALWAYS_ON" != "True" ]; then
    exit 0
  fi
fi

PUA_PY="$(pua_python_cmd 2>/dev/null || true)"
[ -n "$PUA_PY" ] || exit 0
HOOK_INPUT="$(cat)"

# Require the host's own workspace identity; never infer one from the process.
EVENT_CWD="$(printf '%s' "$HOOK_INPUT" | "$PUA_PY" -c '
import json, sys
try:
    data = json.load(sys.stdin)
    value = data.get("cwd", "") if isinstance(data, dict) else ""
    print(value if isinstance(value, str) else "")
except Exception:
    pass
' 2>/dev/null || true)"
[ -n "$EVENT_CWD" ] || exit 0

HOME_VALUE="${HOME:-}"
[ -n "$HOME_VALUE" ] || exit 0
PY_HOME="$(pua_to_python_path "$HOME_VALUE")"
PY_CWD="$(pua_to_python_path "$EVENT_CWD")"
PY_HELPER="$(pua_to_python_path "${SCRIPT_DIR}/runtime-state.py")"

STATE_ARGS=()
if [ -n "${PUA_STATE_DIR:-}" ]; then
  # Trusted host-process override only; hook JSON has no state-path field.
  PY_STATE_DIR="$(pua_to_python_path "$PUA_STATE_DIR")"
  STATE_ARGS=(--state-dir "$PY_STATE_DIR")
fi

# A PreCompact command hook may save local state, but it need not inject text.
# Keep stdout empty so it cannot claim a task result or alter user-visible flow.
printf '%s' "$HOOK_INPUT" | "$PUA_PY" "$PY_HELPER" checkpoint \
  --home "$PY_HOME" --cwd "$PY_CWD" ${STATE_ARGS[@]+"${STATE_ARGS[@]}"} >/dev/null 2>&1 || true

exit 0
