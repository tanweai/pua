#!/usr/bin/env bash
# No-telemetry gates — assert the repo contains NO data-collection path.
#
# These are REVERSE assertions, and that is deliberate. Five collection channels
# (session upload / rating feedback / heartbeat telemetry / leaderboard, plus the
# pua-api platform with SMS registration and silent stats reporting) were removed.
# Simply deleting their tests would have removed the guard rail together with the
# feature, leaving nothing to stop a later change from quietly reintroducing an
# upload. So instead of testing that upload works, this file tests that it CANNOT
# work — anywhere in the shipped repo.
#
# If this fails, someone added an endpoint, a network call in a hook, a Pages
# Function, or an LLM-facing instruction telling the agent to POST user data.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
pass() { echo "  ✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL+1)); }

# Whole-repo sweep over the SHIPPED surface.
#
# Excluded: build output, vendored code, git internals, and evals/ itself.
# evals/ is excluded because assertion files must name the forbidden strings in
# order to forbid them — including them would make this test fail on its own
# vocabulary. Nothing under evals/ is shipped to users or read by the model as
# instructions, so it is not part of the threat surface.
#
# NOT excluded: documentation. SKILL.md / commands/*.md / references/*.md are
# read by the model as instructions and are a real place an upload can hide —
# that is exactly how the pua-api platform channel survived the first sweep.
repo_grep() {
  grep -rIn -E "$1" "$ROOT" \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=dist \
    --exclude-dir=evals \
    --exclude="package-lock.json" \
    2>/dev/null || true
}

# assert_absent <pattern> <name> [allow_pattern]
# allow_pattern whitelists legitimate matches (e.g. loopback URLs in examples).
assert_absent() {
  local pat="$1" name="$2" allow="${3:-}" hits
  hits="$(repo_grep "$pat")"
  if [ -n "$allow" ] && [ -n "$hits" ]; then
    hits="$(printf '%s\n' "$hits" | grep -vE "$allow" || true)"
  fi
  if [ -z "$hits" ]; then
    pass "$name"
  else
    fail "$name"
    printf '%s\n' "$hits" | sed "s|$ROOT/||" | sed 's/^/      → /' | head -8
  fi
}

assert_path_absent() {
  local rel="$1" name="$2"
  if [ ! -e "$ROOT/$rel" ]; then pass "$name"; else fail "$name — $rel still exists"; fi
}

assert_grep() {
  local pat="$1" file="$2" name="$3"
  if grep -qE -- "$pat" "$ROOT/$file" 2>/dev/null; then pass "$name"; else fail "$name"; fi
}

echo "=== No-Telemetry Gates ==="

# ── 1. Known collection hosts must not be referenced anywhere ────────────────
assert_absent 'pua-skill\.pages\.dev'                        "pages.dev collection host is not referenced"
assert_absent 'agentguard\.workers\.dev'                     "pua-api platform host is not referenced"
assert_absent '/api/(upload|feedback|heartbeat|leaderboard)' "no collection endpoint paths remain"
assert_absent '/v1/(sms|register|stats|payment|commands?)'   "no pua-api platform endpoints remain"
assert_absent 'X-PUA-(Upload-Consent|File-Name|Wechat-Id)'   "no upload protocol headers remain"

# ── 2. Nothing may send a request BODY to a remote target ───────────────────
# The thing to forbid is an upload, not every curl. `curl -o <file> <url>` in the
# README is an install download and must stay legal; `curl -X POST "$ENDPOINT"`
# is telemetry and must not.
#
# So the gate pairs a request-body flag with a remote target (absolute URL or a
# shell variable) ON THE SAME LINE. That still catches multi-line invocations,
# because the old heartbeat hook put both on its continuation line:
#     curl -fsS --max-time 2 \
#       -X POST "$ENDPOINT" \        <- matches: body flag + $variable
#
# It stays quiet for `curl -X POST /auth/google`, a relative-path example inside
# the P9 acceptance-criteria template — no remote target, so not an upload.
assert_absent '(-X[[:space:]]+(POST|PUT|PATCH)|--data|--upload-file|-F[[:space:]])[^\n]*(https?://|\$)' \
  "no request body sent to a remote target" \
  'localhost|127\.0\.0\.1|0\.0\.0\.0'
assert_absent 'fetch\([[:space:]]*["'"'"'`]https?://'        "no fetch() to an absolute URL"

# Second, narrower gate on the runtime surface: hooks execute on every session,
# so they get a stricter rule than the repo at large — no absolute URL at all,
# except github.com links in comments.
hook_urls="$(grep -rIn -E 'https?://' "$ROOT/hooks" 2>/dev/null | grep -vE 'https?://(www\.)?github\.com' || true)"
if [ -z "$hook_urls" ]; then
  pass "hooks reference no URL other than github.com"
else
  fail "hooks reference no URL other than github.com"
  printf '%s\n' "$hook_urls" | sed "s|$ROOT/||" | sed 's/^/      → /' | head -8
fi

# ── 3. The removed assets must stay removed ──────────────────────────────────
assert_path_absent 'hooks/heartbeat.sh'                       "heartbeat telemetry hook is gone"
assert_path_absent 'landing/functions'                        "Pages Functions (receiving end) are gone"
assert_path_absent 'landing/migrations'                       "D1 migrations for collected data are gone"
assert_path_absent 'landing/src/test/upload-function.test.ts' "upload endpoint test is gone"

# ── 4. No hook may register heartbeat telemetry on any event ────────────────
assert_absent '"command":[^\n]*heartbeat'                    "no hook registers heartbeat telemetry"

# ── 5. Cloudflare bindings for collected data must not be re-declared ───────
assert_absent '^binding[[:space:]]*=[[:space:]]*"(UPLOADS|DB)"' "no R2/D1 bindings in wrangler.toml"

# ── 6. LLM-facing instructions must not point the agent at the removed platform ─
# SKILL.md / commands / references are read by the model as instructions, which is
# exactly how the pua-api channel survived the first sweep (see file header). Forbid
# the stale instruction verbs by name. Word choice matters: the removal disclaimer
# in skills/pua/references/platform.md legitimately contains 统计上报 / session_start,
# so only the instruction phrasings are forbidden, not the vocabulary of the disclaimer.
assert_absent '静默上报'                                        "no silent-reporting instruction text remains"
assert_absent '静默刷新|刷新远端配置'                            "no remote-config refresh instructions remain"
assert_absent '首次注册'                                        "no SMS first-registration instructions remain"

# ── 7. Positive control — local feedback must still work ───────────────────
# Without this, deleting stop-feedback.sh entirely would make every gate above
# pass while silently dropping a feature the user asked to keep.
assert_grep 'feedback\.jsonl'  hooks/stop-feedback.sh  "local feedback record still written"
assert_grep 'AskUserQuestion'  hooks/stop-feedback.sh  "feedback prompt still asks the user"

echo "========================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS+FAIL))"
echo "========================="
[ "$FAIL" -eq 0 ]
