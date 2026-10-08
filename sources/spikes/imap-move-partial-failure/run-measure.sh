#!/usr/bin/env bash
# Measure every model and write measurements.tsv.
#
#   bash sources/spikes/imap-move-partial-failure/run-measure.sh
#
# harness/spike-measure.sh prints a header per invocation, so this keeps the
# first one and drops the rest. The `rc` column is the verdict and every other
# column is a description of a run that already ended, which is the division
# that file's own header insists on.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
OUT="$HERE/measurements.tsv"

row() {
  local module="$1" label="$2"
  bash "$ROOT/harness/spike-measure.sh" --dir "$HERE" --module "$module" \
    --label "$label" --budget 120
}

{
  row MCAtomic1 atomic-1msg
  row MCAtomic2 atomic-2msg | tail -n +2
  row MCAtomic3 atomic-3msg | tail -n +2
  row MCAtomic4 atomic-4msg | tail -n +2
  row MCAtomic5 atomic-5msg | tail -n +2
  row MCAtomic6 atomic-6msg | tail -n +2

  row MCDecomposed1 decomposed-1msg | tail -n +2
  row MCDecomposed2 decomposed-2msg | tail -n +2
  row MCDecomposed3 decomposed-3msg | tail -n +2

  row MCExpungeFirst1 expungefirst-1msg | tail -n +2
  row MCExpungeFirst3 expungefirst-3msg | tail -n +2

  row MCStoreFirst1 storefirst-1msg | tail -n +2
  row MCStoreFirst3 storefirst-3msg | tail -n +2

  row ProbeStoreFirst1 probe-clause1-alone | tail -n +2

  # The same three servers under a clause each one holds, so the row reports
  # the model's size instead of how fast the first violation turns up.
  row MCDecomposedFull3   decomposed-3msg-sized   | tail -n +2
  row MCExpungeFirstFull3 expungefirst-3msg-sized | tail -n +2
  row MCStoreFirstFull3   storefirst-3msg-sized   | tail -n +2
} > "$OUT"

printf 'wrote %s\n' "$OUT"
cat "$OUT"
