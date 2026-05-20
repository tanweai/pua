#!/usr/bin/env bash
# Unit tests for hooks/precompact-checkpoint.sh
#
# Verifies the three documented behaviors:
#   1. Empty/missing stdin → silent exit 0, no journal written
#   2. Transcript without PUA markers → silent exit 0, no journal written
#   3. Transcript with PUA markers → journal written with marker count
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/precompact-checkpoint.sh"
JOURNAL="${HOME:-~}/.pua/builder-journal.md"

PASS=0
FAIL=0

assert() {
  local label="$1" cond="$2"
  if [ "$cond" = "true" ]; then
    echo "  ✅ PASS: $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

echo "=== precompact-checkpoint.sh unit tests ==="

# Test 1: empty stdin
echo "Test 1: empty stdin → silent exit, no journal"
rm -f "$JOURNAL"
echo "" | bash "$HOOK"
rc=$?
[ "$rc" -eq 0 ] && c1="true" || c1="false"
assert "exit 0" "$c1"
[ ! -f "$JOURNAL" ] && c2="true" || c2="false"
assert "no journal written" "$c2"

# Test 2: transcript without PUA markers
echo "Test 2: transcript without markers → silent exit, no journal"
TRANSCRIPT=$(mktemp -t pua-pc-nomark.XXXXXX)
printf 'log line\nno markers here\n' > "$TRANSCRIPT"
printf '{"transcript_path":"%s"}' "$TRANSCRIPT" | bash "$HOOK"
rc=$?
[ "$rc" -eq 0 ] && c1="true" || c1="false"
assert "exit 0" "$c1"
[ ! -f "$JOURNAL" ] && c2="true" || c2="false"
assert "no journal written" "$c2"
rm -f "$TRANSCRIPT"

# Test 3: transcript with PUA markers
echo "Test 3: transcript with markers → journal written"
TRANSCRIPT=$(mktemp -t pua-pc-mark.XXXXXX)
printf 'line\n[PUA生效 🔥] did extra\n[PIP-REPORT] something\n' > "$TRANSCRIPT"
printf '{"transcript_path":"%s"}' "$TRANSCRIPT" | bash "$HOOK"
rc=$?
[ "$rc" -eq 0 ] && c1="true" || c1="false"
assert "exit 0" "$c1"
[ -f "$JOURNAL" ] && c2="true" || c2="false"
assert "journal written" "$c2"
if [ -f "$JOURNAL" ]; then
  grep -q "pua_triggered_count: 2" "$JOURNAL" && c3="true" || c3="false"
  assert "marker count correct (2)" "$c3"
  grep -q "Timestamp" "$JOURNAL" && c4="true" || c4="false"
  assert "timestamp section present" "$c4"
fi
rm -f "$TRANSCRIPT" "$JOURNAL"

echo "==========================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS+FAIL))"
echo "==========================================="

[ "$FAIL" -eq 0 ] || exit 1
