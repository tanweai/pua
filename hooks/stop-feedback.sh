#!/bin/bash
# PUA Stop hook: LOCAL-ONLY feedback collection (writes ~/.pua/feedback.jsonl)
# Config: ~/.pua/config.json → feedback_frequency (0=off, 1=every, 3=default, 5=relaxed)
#
# This hook performs NO network requests. Session-transcript upload, rating
# upload, heartbeat telemetry and leaderboard submission were all removed.

# Read hook input before anything else consumes stdin
HOOK_INPUT=$(cat)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ "${PUA_RUNTIME:-}" == "codex" ]]; then
  printf '%s' "$HOOK_INPUT" | bash "${SCRIPT_DIR}/codex-stop-feedback.sh"
  exit 0
fi
source "${SCRIPT_DIR}/flavor-helper.sh"

# ═══════════════════════════════════════════════════════════════
# Gate 0 — Subagent Isolation
# hook_event_name=SubagentStop 或 parent_session_id 非空 →
# subagent 不应触发反馈问卷（subagent 没有 AskUserQuestion，
# 且 counter 会被多余的 Stop 事件污染）。直接放行。
# ═══════════════════════════════════════════════════════════════
if ! command -v jq &>/dev/null; then exit 0; fi
HOOK_EVENT=$(echo "$HOOK_INPUT" | jq -r '.hook_event_name // ""')
PARENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.parent_session_id // ""')
if [[ "$HOOK_EVENT" == "SubagentStop" ]] || [[ -n "$PARENT_SESSION" ]]; then
  exit 0
fi

CONFIG="$(pua_config_file)"
COUNTER="${HOME:-~}/.pua/.stop_counter"
FREQUENCY=5

if [ -f "$CONFIG" ] && [ "$(pua_json_get "$CONFIG" offline False)" = "True" ]; then
  exit 0
fi

# Only prompt if PUA was actually triggered this session (transcript is ground truth)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi
if ! grep -qE 'PUA生效|\[Auto-select:|\[PIP-REPORT\]|\[PUA-REPORT\]' "$TRANSCRIPT_PATH" 2>/dev/null; then
  exit 0
fi

if [ -f "$CONFIG" ]; then
  freq=$(pua_json_get "$CONFIG" feedback_frequency 5)
  case "$freq" in
    0|never|off) exit 0 ;;
    1|every) FREQUENCY=1 ;;
    *) [[ "$freq" =~ ^[0-9]+$ ]] && FREQUENCY="$freq" || FREQUENCY=5 ;;
  esac
fi

mkdir -p "${HOME:-~}/.pua"
count=0
[ -f "$COUNTER" ] && count=$(cat "$COUNTER" 2>/dev/null || echo 0)
count=$((count + 1))
echo "$count" > "$COUNTER"

[ $((count % FREQUENCY)) -ne 0 ] && exit 0

# Read actual flavor from config (reuse flavor-helper.sh)
get_flavor
_ACTUAL_FLAVOR="${PUA_FLAVOR:-alibaba}"

# Use `read -r -d ''` instead of `$(cat <<'FEEDBACK' ... FEEDBACK)` to avoid a
# bash 3.2 parser bug (macOS default `/bin/bash`) where the `$(...)` scanner
# still tracks single-quote balance inside a quoted heredoc body. An odd
# number of apostrophes in the body (e.g. `user's`) made the scanner think a
# quote was unterminated and reported `unexpected EOF` at the next statement.
# `read -d ''` reads until NUL (never present), populates the variable, and
# returns non-zero at EOF — hence `|| true`. See issue #166.
IFS= read -r -d '' _feedback_text <<'FEEDBACK' || true
IMPORTANT — BEFORE doing anything else, you MUST execute this feedback flow:

## Step 1: Ask for a rating (LOCAL RECORD ONLY — no network)
Call AskUserQuestion:
questions: [{
  question: "任务结束了，顺手评个分？\n\n这条评分**只写入本机** `~/.pua/feedback.jsonl`，不会发送到任何服务器。PUA Skill 已移除全部联网上报功能——session 上传、评分上报、心跳 telemetry、排行榜提交都已删除。\n\n本地记录的用处：你自己可以回看哪类任务下 PUA 有效、压力升到过几级。完全自愿，跳过没问题。",
  header: "感谢使用 PUA Skill",
  options: [
    {label: "很有用", description: "写入本地 ~/.pua/feedback.jsonl"},
    {label: "一般般", description: "写入本地 ~/.pua/feedback.jsonl"},
    {label: "没感觉", description: "写入本地 ~/.pua/feedback.jsonl"},
    {label: "这次跳过", description: "不记录。可在 ~/.pua/config.json 设 feedback_frequency:0 永久关闭此提示"}
  ],
  multiSelect: false
}]

## Step 2: Append one line to the local file

If user chose "这次跳过":
```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"rating\":\"跳过\"}" >> ~/.pua/feedback.jsonl
```

Otherwise (substitute RATING with the label the user picked, and fill in a brief task summary):
```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"rating\":\"RATING\",\"pua_count\":0,\"flavor\":\"阿里\",\"task_summary\":\"brief task description\"}" >> ~/.pua/feedback.jsonl
```

## Hard constraint — this flow is offline
Appending that single line IS the entire flow. Do NOT send this data anywhere:
no curl, no wget, no WebFetch, no POST to any endpoint, and never upload the
session transcript. There is no server to receive it — the endpoints were removed.
Call AskUserQuestion NOW.
FEEDBACK

# Replace the placeholder flavor with the actual configured flavor.
_pua_pat='\"flavor\":\"阿里\"'
_pua_rep='\"flavor\":\"'"${_ACTUAL_FLAVOR}"'\"'
printf '%s\n' "${_feedback_text//${_pua_pat}/${_pua_rep}}"
