#!/usr/bin/env bash
# Measure every model in this directory and write measurements.tsv.
#
# Every row comes from harness/spike-measure.sh, whose rc column is the only
# verdict and whose other columns are descriptive (V2-PLAN.md section 5.1).
#
# Repo root from BASH_SOURCE, never a literal path (bead tla-1hf).
#
# Run:  bash measure.sh

set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
DIR="sources/spikes/progressive-sync-stale-status"
OUT="$HERE/measurements.tsv"

MODELS=(
  "MCBroken2:broken-2cohort"
  "MCFixed2:fixed-2cohort"
  "MCBroken3:broken-3cohort-all-four"
  "MCBrokenInversion:broken-3cohort-inversion-only"
  "MCBrokenDivergence:broken-3cohort-divergence-only"
  "MCBrokenStranded:broken-3cohort-stranded-only"
  "MCFixed3:fixed-3cohort"
  "MCFixed4:fixed-4cohort"
  "MCFixed5:fixed-5cohort"
  "MCFixed6:fixed-6cohort"
  "MCFixed3Rev2:fixed-3cohort-2commits"
  "MCNoRestartFixed1:norestart-fixed-1commit"
  "MCNoRestartFixed:norestart-fixed-2commits"
  "MCInflightBroken:inflight-broken-3cohort"
  "MCInflightFixed:inflight-fixed-3cohort"
  "DeadSyncProbe:dead-action-control"
)

first=1
: > "$OUT"
for entry in "${MODELS[@]}"; do
  module="${entry%%:*}"
  label="${entry#*:}"
  out="$( cd "$ROOT" && bash harness/spike-measure.sh \
            --dir "$DIR" --module "$module" --budget 120 --label "$label" )"
  if [ "$first" = "1" ]; then
    printf '%s\n' "$out" >> "$OUT"
    first=0
  else
    # Drop the header row on every run after the first.  A here-string, never
    # a live pipe into tail: a pipeline into an early-exiting consumer returns
    # 141 under pipefail (bead tla-kr9).
    tail -n +2 <<<"$out" >> "$OUT"
  fi
done

cat "$OUT"
