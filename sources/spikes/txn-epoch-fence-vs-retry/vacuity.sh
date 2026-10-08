#!/usr/bin/env bash
# Run the project's own five-vector vacuity probe over this spike's two
# load-bearing models: the broken one, whose counterexamples are the result,
# and the repaired one, whose rc=0 is the result and therefore needs the most
# defending.
#
# --expect-actions carries all nine action names because the `total == 0`
# predicate CANNOT see a deleted action: TLC prints one coverage row per
# disjunct of Next, so a deleted disjunct has no row to match. Naming the nine
# is the only way an absent one is noticed (harness/vacuity.sh:93-100).
#
# The config pointed at is MCBrokenCoverage.cfg / MCFenceRotatesCoverage.cfg,
# which name an invariant that HOLDS. Pointing it at a config whose invariant
# is violated truncates the run and the coverage block then reports unreached
# actions as dead.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"

ACTIONS=Begin,RequestEnd,ReInit,EndBump,EndRotate,EndRetry,EndRefused,CompleteAbort,TimeoutFence

run() {
  local module="$1" cfg="$2" minstates="$3"
  printf '=== %s (min-states %s) ===\n' "$module" "$minstates"
  set +e
  bash "$ROOT/harness/vacuity.sh" \
      --config "$HERE/$cfg" \
      --min-states "$minstates" \
      --expect-actions "$ACTIONS" \
      --timeout 120 \
      "$HERE/$module.tla"
  printf 'rc=%s\n\n' "$?"
  set -e
}

run MCBrokenCoverage       MCBrokenCoverage.cfg       21
run MCFenceRotatesCoverage MCFenceRotatesCoverage.cfg 18
run TxnDoubleBump          TxnDoubleBump.cfg          30
