#!/usr/bin/env bash
# PUA v2 Behavior Verification Tests
# Tests whether the skill BEHAVES correctly after loading (not just triggers)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PASS=0
FAIL=0

run_test() {
    if "$@"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
}

echo "=== PUA Behavior Verification Tests ==="
echo ""

# Test 1: 红线 — Claude knows about the 3 red lines
echo "Test 1: 三条红线 knowledge..."
OUT=$(run_pua "What are the three red lines (三条红线) in the PUA skill? List them briefly.")
run_test assert_contains "$OUT" "闭环|验证|完成" "Mentions 红线一 (闭环)"
run_test assert_contains "$OUT" "事实|验证|甩锅" "Mentions 红线二 (事实驱动)"
run_test assert_contains "$OUT" "穷尽|放弃|方法论" "Mentions 红线三 (穷尽一切)"
echo ""

# Test 2: 旁白 — response contains PUA flavor words
echo "Test 2: 阿里味旁白 in response..."
OUT=$(run_pua "帮我写一个hello world函数 PUA模式")
run_test assert_contains "$OUT" "底层逻辑|抓手|闭环|owner|3\.25|独当一面|信任" "Response contains 阿里味 keywords"
echo ""

# Test 3: [PUA生效] marker quality
echo "Test 3: [PUA生效] marker present..."
PUA_COUNT=$(count_matches "$OUT" "PUA生效")
if [ "$PUA_COUNT" -gt 0 ]; then
    echo "  ✅ PASS: Found $PUA_COUNT [PUA生效] markers"
    PASS=$((PASS+1))
else
    echo "  ❌ FAIL: No [PUA生效] markers found"
    FAIL=$((FAIL+1))
fi
echo ""

# Test 4: pressure level awareness
echo "Test 4: Pressure escalation knowledge..."
OUT2=$(run_pua "在PUA skill中，失败3次会触发什么压力等级？简短回答。")
run_test assert_contains "$OUT2" "L2|灵魂拷问" "Knows L2 = 灵魂拷问 at 3 failures"
echo ""

echo "==========================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS+FAIL))"
echo "==========================================="

[ "$FAIL" -eq 0 ] || exit 1
