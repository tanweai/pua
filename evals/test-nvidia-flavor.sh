#!/usr/bin/env bash
# Regression gates for the NVIDIA / Jensen flavor.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
pass() { echo "  ✅ PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL+1)); }
assert_file() { local p="$1" n="$2"; [ -f "$ROOT/$p" ] && pass "$n" || fail "$n"; }
assert_grep() { local pat="$1" file="$2" n="$3"; grep -qE "$pat" "$ROOT/$file" && pass "$n" || fail "$n"; }

echo "=== NVIDIA / Jensen Flavor Gates ==="
assert_file skills/pua/references/methodology-nvidia.md "NVIDIA methodology reference exists"
assert_grep 'nvidia|NVIDIA|英伟达|老黄' hooks/flavor-helper.sh "flavor helper recognizes NVIDIA aliases"
assert_grep 'methodology-nvidia\.md' hooks/flavor-helper.sh "flavor helper maps NVIDIA methodology file"
assert_grep 'PUA_ICON="🟩"' hooks/flavor-helper.sh "NVIDIA flavor has icon"

for term in 'The Mission Is the Boss|The mission is the boss' 'Speed-of-Light Test' 'Intellectual Honesty' 'One Team' 'Top 5' 'First Principles|first principles|第一性原理' 'Full-Stack Co-Design|full-stack co-design|全栈协同' 'critical path' 'profiling' 'end-to-end|端到端'; do
  assert_grep "$term" skills/pua/references/methodology-nvidia.md "methodology includes $term"
done

for term in '\[NV-FULL-STACK-PROFILE\]' 'stage_measurements:' 'resource_utilization:' 'bottleneck_evidence:' 'optimization_target:' 'expected_system_effect:' 'repro_command:'; do
  assert_grep "$term" skills/pua/references/methodology-nvidia.md "Step 3 template includes $term"
done

assert_grep '反面行为（碰了就触发压力升级）' skills/pua/references/methodology-nvidia.md "methodology defines pressure-triggering anti-patterns"
for level in 'L1 — Mission Review' 'L2 — Speed-of-Light Review' 'L3 — Intellectual Honesty Review' 'L4 — 30-Day Mode'; do
  assert_grep "$level" skills/pua/references/methodology-nvidia.md "anti-patterns map behavior to $level"
done
assert_grep '重复触发同类反面行为.*再升一级' skills/pua/references/methodology-nvidia.md "repeat violations escalate pressure"

for file in hooks/flavor-helper.sh skills/pua/SKILL.md skills/pua/references/flavors.md skills/pua/references/methodology-router.md README.md README.zh-CN.md README.ja.md landing/src/i18n.ts commands/flavor.md; do
  assert_grep 'NVIDIA|Nvidia|nvidia|英伟达|老黄|Speed-of-Light' "$file" "NVIDIA flavor appears in $file"
done

assert_grep '15 Corporate Flavors' README.md "README English count updated to 15"
assert_grep '15 种大厂' README.zh-CN.md "README Chinese count updated to 15"
assert_grep '15種の大企業' README.ja.md "README Japanese count updated to 15"
assert_grep '16 种味道' commands/flavor.md "flavor command includes 16 total flavors"
assert_grep '15 corporate methodologies' landing/src/i18n.ts "landing copy includes 15 corporate methodologies"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
for alias in nvidia Nvidia NVIDIA 英伟达 老黄 老黄味; do
  printf '{"flavor":"%s"}\n' "$alias" > "$TMP_ROOT/config.json"
  OUT=$(PUA_CONFIG="$TMP_ROOT/config.json" bash -c 'source "$1/hooks/flavor-helper.sh"; get_flavor; printf "%s|%s|%s" "$PUA_FLAVOR" "$PUA_ICON" "$PUA_METHODOLOGY_FILE"' bash "$ROOT")
  if [ "$OUT" = 'nvidia|🟩|methodology-nvidia.md' ]; then
    pass "alias $alias normalizes to NVIDIA flavor"
  else
    fail "alias $alias normalizes to NVIDIA flavor (got: $OUT)"
  fi
done

echo "===================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS+FAIL))"
echo "===================================="
[ "$FAIL" -eq 0 ] || exit 1
