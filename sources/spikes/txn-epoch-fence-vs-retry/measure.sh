#!/usr/bin/env bash
# Re-measure every model in this spike and rewrite measurements.tsv.
#
# The header row and every data row come from harness/spike-measure.sh, so the
# rc column is the verdict and every other column is descriptive -- the one
# rule that file has.
#
# The repository root is resolved from BASH_SOURCE and never from a literal
# path. A hardcoded `cd /home/.../tla-puzzles` in scripts/gen-curriculum-map.sh
# used to write into the MAIN checkout when the script was run from a worktree,
# and that is the one leak a `git diff --stat` footprint check cannot see
# (bead tla-1hf).
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"
REL="sources/spikes/txn-epoch-fence-vs-retry"
OUT="$HERE/measurements.tsv"

# The sweep, in the order REPORT.md reads them.
MODELS=(
  TxnBroken
  MCBrokenLiveness
  MCBrokenNoFair
  MCBrokenStuck
  MCBrokenDeadlock
  MCWitnessOngoing
  MCWitnessAborted
  MCWitnessRotation
  MCWitnessCeiling
  TxnFenceRotates
  MCFenceRotatesLiveness
  MCFenceRotatesCeiling
  MCFenceRotatesWork
  TxnBeginChecks
  MCBeginChecksLiveness
  MCBeginChecksWork
  TxnRetryGuarded
  MCRetryGuardedLiveness
  MCRetryGuardedWork
  TxnDoubleBump
  MCDoubleBumpLiveness
  MCDoubleBumpFenceable
  MCBroken4
  MCBroken16
  MCFenceRotates16
  TxnUnbounded
  MCUnboundedWork
  MCUnboundedFree
  MCBrokenCoverage
  MCFenceRotatesCoverage
  MCReInertProbe
)

first=1
: > "$OUT"
for m in "${MODELS[@]}"; do
  row="$(bash "$ROOT/harness/spike-measure.sh" \
            --dir "$ROOT/$REL" --module "$m" --label "$m" --budget 120)"
  if [ "$first" = 1 ]; then
    head -1 <<<"$row" >> "$OUT"
    first=0
  fi
  tail -1 <<<"$row" >> "$OUT"
  tail -1 <<<"$row"
done
