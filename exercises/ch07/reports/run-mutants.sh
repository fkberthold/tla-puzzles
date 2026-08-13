#!/usr/bin/env bash
# Run every seeded ch07 mutant through harness/verdict.sh and print one row
# per mutant: id, module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch07/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch07-mut`, matching the seeder's default.
#
# Every ch07 reference is a PlusCal spec, so every mutant is re-translated
# first. TLC checks the translation and not the algorithm comment, so an edit
# inside the PlusCal block does nothing until pcal has run again. Several ch07
# patterns are pinned to the PlusCal copy by indentation, which only works
# because of this step.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch07-mut}"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(ls "$d"*.tla)
  module=$(basename "$tla" .tla)
  pcal "$tla" >/dev/null 2>&1
  token=$(bash harness/verdict.sh "$tla" -c "$d$module.cfg" 2>/dev/null)
  rc=$?
  printf '%-4s %-12s %-20s rc=%s\n' "$id" "$module" "$token" "$rc"
done
