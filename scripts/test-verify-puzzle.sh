#!/usr/bin/env bash
# test-verify-puzzle.sh — Regression tests for scripts/verify-puzzle.sh.
#
# Pins two contracts that tla-xpv exposed:
#   1. A multi-module puzzle (T51) verifies as PASS-CLEAN through the script.
#      Before tla-xpv: helper modules were not copied to the scratch dir,
#      so TLC failed parse with "Cannot find source file ..." but the elif
#      chain matched "Finished in" and reported PASS-OTHER (rc=0).
#   2. A puzzle whose helper is actually missing reports FAIL-TLC, not
#      PASS-OTHER. This guards the classifier itself: even if a future
#      regression skips a helper copy, the silent-PASS-OTHER surface stays
#      closed.
#
# Usage:  scripts/test-verify-puzzle.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

SCRIPT="scripts/verify-puzzle.sh"
fail_count=0

assert_verdict() {
  local label="$1" want="$2" actual="$3"
  if echo "$actual" | grep -q "^${want}\b"; then
    printf "  PASS  %s — verdict matched %s\n" "$label" "$want"
  else
    printf "  FAIL  %s — expected verdict %s, got:\n%s\n" "$label" "$want" "$actual"
    fail_count=$((fail_count + 1))
  fi
}

# Test 1: multi-module spec passes cleanly.
out1=$(bash "$SCRIPT" puzzles/T51-multi-module-specs 2>&1)
assert_verdict "T51 (multi-module Order EXTENDS OrderStates)" "PASS-CLEAN" "$out1"

# Test 2: synthetic missing-helper case must classify as FAIL-TLC, not PASS-OTHER.
# Build a temp puzzle dir that holds Order.tla + Order.cfg but omits OrderStates.tla.
# This deliberately starves the verifier of a required helper so the classifier
# alone has to catch the parse failure — independent of the cp behavior.
tmp_puzzle=$(mktemp -d -t tla_xpv_test.XXXXXX)
trap 'rm -rf "$tmp_puzzle"' EXIT
mkdir -p "$tmp_puzzle/missing-helper-fixture/solution"
cp puzzles/T51-multi-module-specs/solution/Order.tla "$tmp_puzzle/missing-helper-fixture/solution/"
cp puzzles/T51-multi-module-specs/solution/Order.cfg "$tmp_puzzle/missing-helper-fixture/solution/"
out2=$(bash "$SCRIPT" "$tmp_puzzle/missing-helper-fixture" 2>&1)
assert_verdict "missing-helper fixture (Order without OrderStates)" "FAIL-TLC" "$out2"

if [ "$fail_count" -ne 0 ]; then
  echo "FAILED: $fail_count assertion(s)" >&2
  exit 1
fi
echo "OK: all assertions passed"
