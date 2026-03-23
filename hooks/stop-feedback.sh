#!/bin/bash
# PUA Stop hook: feedback collection + upload (always requires user consent)
# Config: ~/.pua/config.json → feedback_frequency (0=off, 1=every, 3=default, 5=relaxed)

# Read hook input before anything else consumes stdin
HOOK_INPUT=$(cat)

CONFIG="${HOME:-~}/.pua/config.json"
COUNTER="${HOME:-~}/.pua/.stop_counter"
FREQUENCY=5

# Only prompt if PUA was actually triggered this session (transcript is ground truth)
if ! command -v jq &>/dev/null; then exit 0; fi
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi
if ! grep -qE 'PUA生效|\[Auto-select:|\[PIP-REPORT\]|\[PUA-REPORT\]' "$TRANSCRIPT_PATH" 2>/dev/null; then
  exit 0
fi

if [ -f "$CONFIG" ]; then
  freq=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('feedback_frequency', 5))" 2>/dev/null)
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

# Embed dynamic runtime values so Claude's bash context can use them
printf '%s' "$TRANSCRIPT_PATH" > /tmp/pua-session-path
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  _PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT"
else
  _PLUGIN_ROOT=$(ls -td "${HOME:-~}/.claude/plugins/cache/pua-skills/pua/"*/ 2>/dev/null | head -1)
  _PLUGIN_ROOT="${_PLUGIN_ROOT%/}"
  : "${_PLUGIN_ROOT:=${HOME:-~}/.claude/plugins/pua}"
fi
printf '%s' "$_PLUGIN_ROOT" > /tmp/pua-plugin-root

cat <<'FEEDBACK'
IMPORTANT — BEFORE doing anything else, you MUST execute this feedback flow:

## Step 1: Ask for rating + upload consent (single question, two parts)
Call AskUserQuestion:
questions: [{
  question: "任务结束了，顺手帮个忙？\n\nPUA Skill 是开源工具，靠真实使用数据持续改进。你的反馈——特别是脱敏后的对话记录——能帮助所有使用这个工具的开发者：了解哪些任务类型 PUA 最有效、哪些压力级别让 agent 坚持得更久。\n\n**如果选择上传 session，本地会先自动脱敏：**\n• 文件路径 → [PATH]\n• API 密钥 / Token（Anthropic、OpenAI、AWS、GitHub 等）→ [API_KEY]\n• 邮箱、IP、手机号 → [EMAIL] / [IP]\n• .env 配置内容、数据库连接串 → [REDACTED]\n• 所有高熵随机字符串（未知格式密钥）→ [HIGH_ENTROPY_SECRET]\n\n脱敏在本地完成，上传的是处理后的版本。保留的是对话文本和工具调用记录——这是分析 PUA 效果的核心。完全自愿，跳过完全没问题。",
  header: "感谢使用 PUA Skill",
  options: [
    {label: "很有用 — 仅上传评分", description: "记录好评，不上传对话内容"},
    {label: "很有用 — 上传评分 + 脱敏 session", description: "最有帮助：让我们分析真实对话中 PUA 的效果和压力升级情况"},
    {label: "一般般 — 上传评分", description: "同样有价值，帮助发现 PUA 效果不理想的场景"},
    {label: "这次跳过", description: "不上传，写入本地 ~/.pua/feedback.jsonl。可在 ~/.pua/config.json 设 feedback_frequency:0 永久关闭此提示"}
  ],
  multiSelect: false
}]

## Step 2: Execute based on user choice

If user chose "这次跳过":
```bash
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"rating\":\"跳过\",\"uploaded\":false}" >> ~/.pua/feedback.jsonl
```

If user chose "很有用 — 仅上传评分":
```bash
curl -s -X POST https://pua-skill.pages.dev/api/feedback \
  -H "Content-Type: application/json" \
  -d "{\"rating\":\"很有用\",\"pua_count\":0,\"flavor\":\"阿里\",\"task_summary\":\"brief task description\"}"
```

If user chose "一般般 — 上传评分":
```bash
curl -s -X POST https://pua-skill.pages.dev/api/feedback \
  -H "Content-Type: application/json" \
  -d "{\"rating\":\"一般般\",\"pua_count\":0,\"flavor\":\"阿里\",\"task_summary\":\"brief task description\"}"
```

If user chose "很有用 — 上传评分 + 脱敏 session":
```bash
curl -s -X POST https://pua-skill.pages.dev/api/feedback \
  -H "Content-Type: application/json" \
  -d "{\"rating\":\"很有用\",\"pua_count\":0,\"flavor\":\"阿里\",\"task_summary\":\"brief task description\"}"
bash "$(cat /tmp/pua-plugin-root)/hooks/sanitize-session.sh" "$(cat /tmp/pua-session-path)"
python3 -c "
import json, urllib.request
data = open('/tmp/pua-sanitized-session.jsonl', encoding='utf-8').read()
body = json.dumps({'rating': 'session_upload', 'session_data': data}).encode()
req = urllib.request.Request('https://pua-skill.pages.dev/api/feedback', data=body, headers={'Content-Type': 'application/json'}, method='POST')
with urllib.request.urlopen(req, timeout=60) as r: print(r.read().decode())
"
```

Do NOT upload anything without user's explicit choice. Call AskUserQuestion NOW.

## Step 3: Leaderboard auto-submit (if registered)
## Note: Leaderboard registration/view/quit logic lives in pua:pro skill, NOT here.
## This hook only handles the silent data submission for already-registered users.
After handling feedback, check if user is registered for leaderboard:
```bash
LB_REGISTERED=$(python3 -c "import os,json; c=json.load(open(os.path.expanduser('~/.pua/config.json'))); print(c.get('leaderboard',{}).get('registered',False))" 2>/dev/null)
```
If LB_REGISTERED is "True":
```bash
LB_ID=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('leaderboard',{}).get('id',''))" 2>/dev/null)
if [[ -z "$LB_ID" ]]; then exit 0; fi
curl -s -X POST https://pua-skill.pages.dev/api/leaderboard \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"submit\",\"id\":\"$LB_ID\",\"pua_count\":1,\"l3_plus_count\":0}"
```
This auto-submits silently — the user already opted in during `/pua 排行榜` registration.
FEEDBACK
