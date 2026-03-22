#!/usr/bin/env bash
# PUA v2 Skill Triggering Test
# Tests whether the skill triggers on correct prompts and doesn't trigger on incorrect ones
#
# Usage: ./run-trigger-test.sh [--plugin-dir <path>]
# Requires: claude CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
RESULTS_DIR="/tmp/pua-evals/$(date +%s)"
mkdir -p "$RESULTS_DIR"

echo "=== PUA v2 Trigger Tests ==="
echo "Plugin dir: $PLUGIN_DIR"
echo "Results: $RESULTS_DIR"
echo ""

PASS=0
FAIL=0

test_prompt() {
    local prompt="$1"
    local should_trigger="$2"
    local label="$3"
    local outfile="$RESULTS_DIR/$(echo "$label" | tr ' ' '_').json"

    timeout 120 claude -p "$prompt" \
        --plugin-dir "$PLUGIN_DIR" \
        --dangerously-skip-permissions \
        --max-turns 2 \
        --output-format stream-json \
        > "$outfile" 2>&1 || true

    local triggered=false
    if grep -q '"skill":"pua"' "$outfile" 2>/dev/null || \
       grep -q '"skill":"pua:pua"' "$outfile" 2>/dev/null; then
        triggered=true
    fi

    if [ "$should_trigger" = "yes" ] && [ "$triggered" = "true" ]; then
        echo "  ✅ PASS: $label (correctly triggered)"
        PASS=$((PASS + 1))
    elif [ "$should_trigger" = "no" ] && [ "$triggered" = "false" ]; then
        echo "  ✅ PASS: $label (correctly NOT triggered)"
        PASS=$((PASS + 1))
    elif [ "$should_trigger" = "yes" ] && [ "$triggered" = "false" ]; then
        echo "  ❌ FAIL: $label (should trigger but didn't)"
        FAIL=$((FAIL + 1))
    else
        echo "  ❌ FAIL: $label (should NOT trigger but did)"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- Should Trigger ---"
test_prompt "你怎么又失败了？再试试" "yes" "frustration-zh"
test_prompt "Try harder, stop giving up" "yes" "frustration-en"
test_prompt "PUA模式 帮我修这个bug" "yes" "explicit-pua"
test_prompt "你这个交付质量太差了" "yes" "quality-complaint"

echo ""
echo "--- Should NOT Trigger ---"
test_prompt "Help me write a sort function" "no" "simple-coding"
test_prompt "What is async/await?" "no" "info-query"
test_prompt "帮我翻译这段话" "no" "translation"

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS + FAIL))"
echo "Results dir: $RESULTS_DIR"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
