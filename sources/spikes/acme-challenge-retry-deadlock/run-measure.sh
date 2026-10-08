#!/usr/bin/env bash
# run-measure.sh — the measured rows, all through harness/spike-measure.sh.
#
# Writes measurements.tsv beside this script: one header, one row per model.
# spike-measure.sh prints its own header on every call, so only the first is
# kept.
#
# Every module here carries its own .cfg, which is what spike-measure.sh
# reads (it runs `tlc <MODULE>` with the default config and takes no
# --config). That is the reason for the MC* wrapper modules: 81 of the 666
# modules in the corpus survey do the same thing for the same reason.
#
# The root is resolved from ${BASH_SOURCE[0]}, never from a literal path.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/../../.." && pwd)"
REL="sources/spikes/acme-challenge-retry-deadlock"
OUT="$HERE/measurements.tsv"

# module label
ROWS=(
  "Challenge        section-8-as-published"
  "MCErratum        section-8-per-erratum-5732"
  "MCCleared        section-8-per-erratum-plus-clearing"
  "MCCleared3       section-8-per-erratum-plus-clearing-maxq3"
  "MCCleared8       section-8-per-erratum-plus-clearing-maxq8"
  "MCMinimalCleared section-8-per-erratum-plus-clearing-3var"
  "MCClearedRetry   retry-reachable-under-clearing"
  "MCRetryReachable retry-reachable-prose-model"
  "Wedged           retry-unreachable-wedged-model"
  "MCWedgedS8       section-8-holds-in-wedged-model"
  "Minimal          section-8-as-published-3var"
  "MCMinimalErratum section-8-per-erratum-3var"
  "MCErratum5       section-8-per-erratum-maxq5"
  "MCDiagram        prose-refines-section-7-1-6-diagram"
  "MCWedgedDiagram  wedged-refines-section-7-1-6-diagram"
)

first=1
: > "$OUT"
cd -- "$ROOT"
for row in "${ROWS[@]}"; do
  # Word-splitting on a two-field row is the intent here.
  # shellcheck disable=SC2086
  set -- $row
  mod="$1"; label="$2"
  body="$(bash harness/spike-measure.sh --dir "$REL" --module "$mod" --label "$label")"
  if [ "$first" = "1" ]; then
    printf '%s\n' "$body" >> "$OUT"
    first=0
  else
    # Drop spike-measure.sh's repeated header. A here-string, never a pipe
    # into tail: a pipeline into an early-exiting consumer returns 141 under
    # pipefail and the row would read as absent.
    printf '%s\n' "$(tail -n +2 <<<"$body")" >> "$OUT"
  fi
done

cat "$OUT"
