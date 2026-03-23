#!/bin/bash

# PUA Loop Stop Hook
# Prevents session exit when a pua-loop is active
# Feeds Claude's output back as input to continue the loop
#
# Adapted from Ralph Wiggum by Anthropic (MIT License)
# https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum

set -euo pipefail
command -v jq &>/dev/null || { echo "jq not found, skipping" >&2; exit 0; }

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if pua-loop is active
RALPH_STATE_FILE=".claude/pua-loop.local.md"

if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# Normalize CRLF → LF (Claude Code on Windows writes CRLF; sed/awk fail to match ^---$ on ---\r lines)
TEMP_NORM="${RALPH_STATE_FILE}.norm.$$"
tr -d '\r' < "$RALPH_STATE_FILE" > "$TEMP_NORM" && mv "$TEMP_NORM" "$RALPH_STATE_FILE"

# Parse markdown frontmatter (YAML between ---) and extract values
# || true prevents set -e from triggering when a field is absent (e.g. optional completion_promise)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE" | tr -d '\r')
LOOP_ACTIVE=$(echo "$FRONTMATTER" | grep '^active:' | sed 's/active: *//' || true)
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || true)
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || true)
# Extract completion_promise and strip surrounding quotes if present
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/' || true)

# Check if loop is paused (active: false)
# Legacy state files without active field are treated as active: true
if [[ "$LOOP_ACTIVE" == "false" ]]; then
  # Loop is paused - allow exit, do not block
  exit 0
fi

# Session isolation: the state file is project-scoped, but the Stop hook
# fires in every Claude Code session in that project. If another session
# started the loop, this session must not block (or touch the state file).
# Legacy state files without session_id fall through (preserves old behavior).
STATE_SESSION=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' || true)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')

# Session self-binding on resume: if loop is active but session_id is empty,
# bind this session so the isolation check works correctly going forward.
# Must happen BEFORE the isolation check.
# Pattern matches with or without space after colon (handles both `session_id:` and `session_id: `)
if [[ -z "$STATE_SESSION" ]] && [[ "$HOOK_SESSION" != "" ]]; then
  TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
  sed "s/^session_id:.*/session_id: $HOOK_SESSION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$RALPH_STATE_FILE"
  STATE_SESSION="$HOOK_SESSION"
fi

if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# Validate numeric fields before arithmetic operations
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  PUA Loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   PUA Loop is stopping. Run /pua-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  PUA Loop: State file corrupted" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "" >&2
  echo "   This usually means the state file was manually edited or corrupted." >&2
  echo "   PUA Loop is stopping. Run /pua-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 PUA Loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  PUA Loop: Transcript file not found" >&2
  echo "   Expected: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a Claude Code internal issue." >&2
  echo "   PUA Loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Read last assistant message from transcript (JSONL format - one JSON per line)
# First check if there are any assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  PUA Loop: No assistant messages found in transcript" >&2
  echo "   Transcript: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a transcript format issue" >&2
  echo "   PUA Loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Extract the most recent assistant text block.
#
# Claude Code writes each content block (text/tool_use/thinking) as its own
# JSONL line, all with role=assistant. So slurp the last N assistant lines,
# flatten to text blocks only, and take the last one.
#
# Capped at the last 100 assistant lines to keep jq's slurp input bounded
# for long-running sessions.
LAST_LINES=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 100) || true
if [[ -z "$LAST_LINES" ]]; then
  echo "⚠️  PUA Loop: Failed to extract assistant messages" >&2
  echo "   PUA Loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Parse the recent lines and pull out the final text block.
# `last // ""` yields empty string when no text blocks exist (e.g. a turn
# that is all tool calls). That's fine: empty text means no <promise> tag,
# so the loop simply continues.
# (Briefly disable errexit so a jq failure can be caught by the $? check.)
set +e
LAST_OUTPUT=$(echo "$LAST_LINES" | jq -rs '
  map(.message.content[]? | select(.type == "text") | .text) | last // ""
' 2>&1)
JQ_EXIT=$?
set -e

# Check if jq succeeded
if [[ $JQ_EXIT -ne 0 ]]; then
  echo "⚠️  PUA Loop: Failed to parse assistant message JSON" >&2
  echo "   Error: $LAST_OUTPUT" >&2
  echo "   This may indicate a transcript format issue." >&2
  echo "   PUA Loop is stopping." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Signal priority: abort > pause > completion promise
# Check for <loop-abort> signal — terminates loop completely
# Use -ne + conditional print so ABORT_TEXT is empty when tag is absent
ABORT_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -ne 'if (/<loop-abort>(.*?)<\/loop-abort>/s) { $t=$1; $t=~s/^\s+|\s+$//g; print $t }' 2>/dev/null || echo "")
if [[ -n "$ABORT_TEXT" ]]; then
  echo "🛑 PUA Loop: Received <loop-abort> signal. Loop terminated."
  echo "   Reason: $ABORT_TEXT"
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Check for <loop-pause> signal — pauses loop, keeps state for resume
# Use -ne + conditional print so PAUSE_TEXT is empty when tag is absent
PAUSE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -ne 'if (/<loop-pause>(.*?)<\/loop-pause>/s) { $t=$1; $t=~s/^\s+|\s+$//g; print $t }' 2>/dev/null || echo "")
if [[ -n "$PAUSE_TEXT" ]]; then
  # Mark loop as paused: set active=false, clear session_id
  TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
  sed "s/^active:.*/active: false/" "$RALPH_STATE_FILE" | \
    sed "s/^session_id:.*/session_id: /" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$RALPH_STATE_FILE"

  echo ""
  echo "⏸️  PUA Loop 已暂停（第 $ITERATION 轮）"
  echo "   Claude 需要人工完成以下操作："
  echo ""
  echo "   $PAUSE_TEXT"
  echo ""
  echo "   完成后，重新打开 Claude Code 会话，Loop 将自动恢复。"
  echo "   状态已保存在 $RALPH_STATE_FILE"
  echo ""
  exit 0
fi

# Check for completion promise (only if set)
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # Extract text from <promise> tags using Perl for multiline support
  # -0777 slurps entire input, s flag makes . match newlines
  # .*? is non-greedy (takes FIRST tag), whitespace normalized
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  # Use = for literal string comparison (not pattern matching)
  # == in [[ ]] does glob pattern matching which breaks with *, ?, [ characters
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "✅ PUA Loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    rm "$RALPH_STATE_FILE"
    exit 0
  fi
fi

# Not complete - continue loop with SAME PROMPT
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---)
# Skip first --- line, skip until second --- line, then print everything after
# Use i>=2 instead of i==2 to handle --- in prompt content
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  PUA Loop: State file corrupted or incomplete" >&2
  echo "   File: $RALPH_STATE_FILE" >&2
  echo "   Problem: No prompt text found" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     • State file was manually edited" >&2
  echo "     • File was corrupted during writing" >&2
  echo "" >&2
  echo "   PUA Loop is stopping. Run /pua-loop again to start fresh." >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# Update iteration in frontmatter (portable across macOS and Linux)
# Create temp file, then atomically replace
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# Build system message with iteration count, PUA pressure level, and signal instructions
SIGNAL_HINT="终止用 <loop-abort>原因</loop-abort>，需人工介入用 <loop-pause>需要什么</loop-pause>"

# Compute PUA pressure level based on iteration count (mirrors SKILL.md escalation table)
if [[ $NEXT_ITERATION -le 3 ]]; then
  PUA_PRESSURE="▎ 第 ${NEXT_ITERATION} 轮迭代，稳步推进。"
elif [[ $NEXT_ITERATION -le 7 ]]; then
  PUA_PRESSURE="▎ 第 ${NEXT_ITERATION} 轮了还没搞定？换方案，别原地打转。"
elif [[ $NEXT_ITERATION -le 15 ]]; then
  PUA_PRESSURE="▎ 第 ${NEXT_ITERATION} 轮。底层逻辑到底是什么？你在重复同一个错误。"
elif [[ $NEXT_ITERATION -le 25 ]]; then
  PUA_PRESSURE="▎ 第 ${NEXT_ITERATION} 轮。3.25 的边缘了。穷尽了吗？"
else
  PUA_PRESSURE="▎ 第 ${NEXT_ITERATION} 轮。最后几轮。要么搞定，要么准备体面退出。"
fi

if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="${PUA_PRESSURE} | 完成后输出 <promise>$COMPLETION_PROMISE</promise> (ONLY when TRUE) | $SIGNAL_HINT"
else
  SYSTEM_MSG="${PUA_PRESSURE} | No completion promise set | $SIGNAL_HINT"
fi

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

# Exit 0 for successful hook execution
exit 0
