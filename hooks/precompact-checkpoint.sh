#!/bin/bash
# PUA v2 PreCompact hook — Bash-side checkpoint writer.
#
# Replaces the earlier "type": "prompt" hook, which fails outside the REPL
# with "Prompt stop hooks are not yet supported outside REPL". Compaction
# can be triggered from non-REPL paths (slash commands, scripted /compact),
# so the hook must run as a plain command and write the file directly.
#
# Trade-off: a shell can't introspect LLM-side state (pressure level, tried
# approaches, next hypothesis). We capture what's on disk and in the
# transcript — timestamp, configured flavor, and a count of PUA markers
# emitted this session. The companion session-restore.sh hook reads the
# resulting journal on the next SessionStart.
#
# Exits 0 silently when no PUA markers are present in the transcript,
# matching the original prompt-mode behavior ("If NONE of these markers
# appear, skip everything below and do nothing").

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./flavor-helper.sh
source "${SCRIPT_DIR}/flavor-helper.sh"

JOURNAL_DIR="${HOME:-~}/.pua"
JOURNAL="${JOURNAL_DIR}/builder-journal.md"

# --- Parse stdin payload (PreCompact event JSON: {transcript_path, ...}) ---
payload=""
if [ ! -t 0 ]; then
  payload=$(cat)
fi

transcript_path=""
if [ -n "$payload" ]; then
  py=$(pua_python_cmd 2>/dev/null) || py=""
  if [ -n "$py" ]; then
    transcript_path=$("$py" -c 'import json,sys
try:
    d=json.loads(sys.stdin.read())
    print(d.get("transcript_path",""))
except Exception:
    print("")' <<<"$payload" 2>/dev/null) || transcript_path=""
  fi
fi

# --- Scan transcript for PUA-activation markers ---
marker_count=0
pua_triggered=0
if [ -n "$transcript_path" ] && [ -r "$transcript_path" ]; then
  marker_count=$(grep -c -E '\[PUA生效|\[PIP-REPORT\]|\[PUA-REPORT\]|\[Auto-select:' "$transcript_path" 2>/dev/null || printf '0')
  marker_count="${marker_count//[^0-9]/}"
  [ -z "$marker_count" ] && marker_count=0
  [ "$marker_count" -gt 0 ] && pua_triggered=1
fi

# Skip silently if PUA wasn't active this session.
if [ "$pua_triggered" -eq 0 ]; then
  exit 0
fi

# --- Resolve current flavor ---
get_flavor 2>/dev/null || true
flavor_label="${PUA_FLAVOR:-unknown} ${PUA_ICON:-}"
flavor_label="${flavor_label% }"

# --- Write journal (shell-side fidelity only; LLM-side state cannot be captured) ---
mkdir -p "$JOURNAL_DIR" 2>/dev/null || true
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$JOURNAL" <<EOF
# PUA v2 Builder Journal — Compaction Checkpoint

## Timestamp
${ts}

## Runtime State (shell-observable only)
- current_flavor: ${flavor_label}
- pua_triggered_count: ${marker_count}
- transcript_path: ${transcript_path:-<unavailable>}

## Note
This checkpoint was written by precompact-checkpoint.sh (a command-mode hook).
LLM-side state (pressure_level, failure_count, tried approaches, next
hypothesis, active task) cannot be captured from outside the model. On the
next SessionStart the assistant should read this file plus the transcript
to reconstruct context.
EOF

exit 0
