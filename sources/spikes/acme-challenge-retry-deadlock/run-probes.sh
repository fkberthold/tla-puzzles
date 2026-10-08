#!/usr/bin/env bash
# run-probes.sh — run every vacuity probe and print module, cfg, token, rc.
#
# EXPECTATION IS DECLARED IN THE TABLE, NOT INFERRED FROM THE RESULT. Each row
# below carries the rc this spike expects, and the script prints agree or
# DISAGREE per row. A probe table that reported only what happened would let a
# probe that silently stopped firing read as a pass.
#
# Verdicts come from exit codes, never from TLC's stdout (V2-PLAN.md 5.1).
# harness/verdict.sh is the only thing that runs tlc here.
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# module cfg expected-rc
ROWS=(
  "Challenge probe-processing.cfg 12"
  "Challenge probe-valid.cfg 12"
  "Challenge probe-invalid.cfg 12"
  "Challenge probe-gaveup.cfg 12"
  "Challenge probe-clientasks.cfg 12"
  "Challenge probe-error.cfg 12"
  "Challenge probe-twoerrors.cfg 12"
  "Challenge probe-query.cfg 12"
  "Wedged wedged-probe-processing.cfg 12"
  "Wedged wedged-probe-invalid.cfg 12"
  "Wedged wedged-probe-query.cfg 12"
  "Wedged wedged-probe-error.cfg 12"
  "Wedged wedged-probe-valid.cfg 12"
  "Wedged wedged-probe-clientasks.cfg 12"
  # The negative control, and the only row whose expectation is not 12. It
  # keeps the "agrees" column honest: a comparison that only ever sees one
  # expected value is not a comparison.
  "Wedged negative-control.cfg 0"
)

printf 'module\tcfg\ttoken\trc\texpected\tagrees\n'
fails=0
for row in "${ROWS[@]}"; do
  # Word-splitting on a three-field row is the intent here.
  # shellcheck disable=SC2086
  set -- $row
  mod="$1"; cfg="$2"; want="$3"
  token="$(bash "$HERE/run-check.sh" "$mod" "$cfg")"
  rc=$?
  agrees="yes"
  if [ "$rc" != "$want" ]; then
    agrees="DISAGREE"
    fails=$((fails + 1))
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$mod" "$cfg" "$token" "$rc" "$want" "$agrees"
done

printf '\n%s probe(s) disagreed with the declared expectation\n' "$fails"
exit 0
