#!/bin/bash

# PUA Sidecar Monitor - PostToolUse Hook
# Records tool calls and detects spinning patterns (repeated failures).
# Writes .claude/pua-triggered.json when spinning is detected.
# Cost: zero tokens — pure shell, no AI calls.

set -uo pipefail

# ─── Config ───
MONITOR_LOG=".claude/pua-monitor.jsonl"
TRIGGER_FILE=".claude/pua-triggered.json"
MAX_LOG_LINES=50
SPIN_THRESHOLD=2  # same pattern N times = spinning

# ─── Ensure .claude/ exists ───
mkdir -p .claude

# ─── Read hook input from stdin ───
HOOK_INPUT=$(cat)

# ─── Extract tool info ───
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // empty' 2>/dev/null || echo "")
TOOL_OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_output // empty' 2>/dev/null || echo "")

# Skip if no tool name
if [[ -z "$TOOL_NAME" ]]; then
  exit 0
fi

# ─── Build a fingerprint for this tool call ───
# For Bash: use the command as fingerprint
# For Edit/Write: use file_path
# For others: use tool_name + first 200 chars of input
case "$TOOL_NAME" in
  Bash)
    FINGERPRINT=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null | head -c 200)
    ;;
  Edit|Write)
    FINGERPRINT=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)
    ;;
  *)
    FINGERPRINT=$(echo "$TOOL_INPUT" | head -c 200)
    ;;
esac

# ─── Detect if this call resulted in an error ───
IS_ERROR="false"
if echo "$TOOL_OUTPUT" | grep -qiE '(error|exception|failed|traceback|ENOENT|EACCES|permission denied|command not found|No such file)' 2>/dev/null; then
  IS_ERROR="true"
fi

# ─── Extract error signature (first error line, max 200 chars) ───
ERROR_SIG=""
if [[ "$IS_ERROR" == "true" ]]; then
  ERROR_SIG=$(echo "$TOOL_OUTPUT" | grep -iE '(error|exception|failed|traceback)' 2>/dev/null | head -1 | head -c 200)
fi

# ─── Append to log ───
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg fp "$FINGERPRINT" \
  --arg err "$IS_ERROR" \
  --arg esig "$ERROR_SIG" \
  '{ts: $ts, tool: $tool, fingerprint: $fp, is_error: ($err == "true"), error_sig: $esig}' \
  >> "$MONITOR_LOG" 2>/dev/null

# ─── Log rotation: keep last N lines ───
if [[ -f "$MONITOR_LOG" ]]; then
  LINE_COUNT=$(wc -l < "$MONITOR_LOG" 2>/dev/null || echo "0")
  if [[ "$LINE_COUNT" -gt "$MAX_LOG_LINES" ]]; then
    TEMP_FILE="${MONITOR_LOG}.tmp.$$"
    tail -n "$MAX_LOG_LINES" "$MONITOR_LOG" > "$TEMP_FILE" 2>/dev/null && mv "$TEMP_FILE" "$MONITOR_LOG"
  fi
fi

# ─── Detect spinning patterns ───
# Only analyze if current call is an error
if [[ "$IS_ERROR" != "true" ]]; then
  # Successful call — clear trigger if it exists (problem may be resolved)
  rm -f "$TRIGGER_FILE" 2>/dev/null
  exit 0
fi

# Count how many recent calls have the same tool + fingerprint + error
SAME_PATTERN_COUNT=0
if [[ -f "$MONITOR_LOG" ]]; then
  SAME_PATTERN_COUNT=$(tail -n 10 "$MONITOR_LOG" | jq -r \
    --arg tool "$TOOL_NAME" \
    --arg fp "$FINGERPRINT" \
    'select(.tool == $tool and .fingerprint == $fp and .is_error == true)' 2>/dev/null | \
    jq -s 'length' 2>/dev/null || echo "0")
fi

# Count recent errors with same error signature (different tools, same underlying error)
SAME_ERROR_COUNT=0
if [[ -n "$ERROR_SIG" ]] && [[ -f "$MONITOR_LOG" ]]; then
  SAME_ERROR_COUNT=$(tail -n 10 "$MONITOR_LOG" | jq -r \
    --arg esig "$ERROR_SIG" \
    'select(.error_sig == $esig and .is_error == true)' 2>/dev/null | \
    jq -s 'length' 2>/dev/null || echo "0")
fi

# Take the higher count
FAIL_COUNT=$SAME_PATTERN_COUNT
if [[ "$SAME_ERROR_COUNT" -gt "$FAIL_COUNT" ]]; then
  FAIL_COUNT=$SAME_ERROR_COUNT
fi

# ─── Write trigger file if spinning detected ───
if [[ "$FAIL_COUNT" -ge "$SPIN_THRESHOLD" ]]; then
  # Determine PUA level
  PUA_LEVEL=1
  if [[ "$FAIL_COUNT" -ge 5 ]]; then
    PUA_LEVEL=4
  elif [[ "$FAIL_COUNT" -ge 4 ]]; then
    PUA_LEVEL=3
  elif [[ "$FAIL_COUNT" -ge 3 ]]; then
    PUA_LEVEL=2
  fi

  jq -n -c \
    --arg ts "$TIMESTAMP" \
    --arg tool "$TOOL_NAME" \
    --arg fp "$FINGERPRINT" \
    --arg esig "$ERROR_SIG" \
    --argjson count "$FAIL_COUNT" \
    --argjson level "$PUA_LEVEL" \
    '{
      triggered_at: $ts,
      fail_count: $count,
      pua_level: $level,
      pattern: {tool: $tool, fingerprint: $fp, error_sig: $esig}
    }' > "$TRIGGER_FILE" 2>/dev/null
fi

exit 0
