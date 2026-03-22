#!/bin/bash
# PUA v2 SessionStart hook
# 1. Check always_on config → auto-load PUA skill
# 2. Check builder-journal → restore compaction state

CONFIG="${HOME:-~}/.pua/config.json"
JOURNAL="${HOME:-~}/.pua/builder-journal.md"

# --- Always-on PUA mode ---
if [ -f "$CONFIG" ]; then
  always_on=$(python3 -c "import os,json; print(json.load(open(os.path.expanduser('~/.pua/config.json'))).get('always_on', False))" 2>/dev/null)
  if [ "$always_on" = "True" ]; then
    cat <<'PUA_ON'
[PUA Always-On Mode]

PUA 默认模式已开启。你的说话方式立即切换为阿里 P8 leader 风格。
底层逻辑、顶层设计、抓手、闭环、颗粒度、3.25——这些词要像呼吸一样自然地嵌入你的每一段输出中。

三条红线生效：闭环意识 / 事实驱动 / 穷尽一切。

> 收到需求，对齐目标，拉通资源。因为信任所以简单——别让信任你的人失望。

PUA_ON
  fi
fi

# --- Compaction state recovery ---
if [ ! -f "$JOURNAL" ]; then
  exit 0
fi

# Check if file was modified within last 2 hours (7200 seconds)
if [ "$(uname)" = "Darwin" ]; then
  age=$(( $(date +%s) - $(stat -f %m "$JOURNAL") ))
else
  age=$(( $(date +%s) - $(stat -c %Y "$JOURNAL") ))
fi

if [ "$age" -gt 7200 ]; then
  exit 0
fi

# File exists and is fresh — output calibration prompt
cat <<'PROMPT'
[PUA v2 Calibration — State Recovery]

A previous context compaction saved PUA runtime state to ~/.pua/builder-journal.md.
You MUST immediately read this file and restore your PUA v2 runtime state:

1. Read ~/.pua/builder-journal.md
2. Restore: pressure_level, failure_count, current_flavor, tried_approaches, active task context
3. Continue the task from where you left off, at the SAME pressure level
4. Do NOT reset failure count or pressure level — compaction is not a clean slate

PROMPT
