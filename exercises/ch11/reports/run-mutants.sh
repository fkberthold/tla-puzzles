#!/usr/bin/env bash
# Run every seeded ch11 mutant through harness/verdict.sh and print one row per
# mutant: id, module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch11/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch11-mut`, matching the seeder's default.
#
# Every ch11 reference is a PlusCal module, so every mutant is re-translated
# first. TLC checks the translation and not the algorithm comment, and a
# property edit lands in both copies, so re-running pcal is what guarantees the
# two agree no matter which copy the seeder touched.
#
# A mutant that does not parse is still a mutant. `pcal` output is discarded and
# its status ignored on purpose: a mutant whose PlusCal is fine but whose TLA+ is
# not must reach verdict.sh, because PARSE_ERROR is one of the verdicts this
# table is measuring.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch11-mut}"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(ls "$d"*.tla)
  module=$(basename "$tla" .tla)
  pcal "$tla" >/dev/null 2>&1
  token=$(bash harness/verdict.sh "$tla" -c "$d$module.cfg" 2>/dev/null)
  rc=$?
  printf '%-4s %-12s %-22s rc=%s\n' "$id" "$module" "$token" "$rc"
done
