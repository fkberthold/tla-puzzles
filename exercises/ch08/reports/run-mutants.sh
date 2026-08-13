#!/usr/bin/env bash
# Run every seeded ch08 mutant through harness/verdict.sh and print one row per
# mutant: id, module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch08/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch08-mut`, matching the seeder's default.
#
# Every mutant is re-translated with pcal first. TLC checks the translation and
# not the algorithm comment, so an edit inside the PlusCal block does nothing
# until pcal has run again. B1 is the proof that the re-translation works, since
# it edits the `define` block and still flips.
#
# KitchenLocks mutants run with -d, matching how the exercise is run. Deadlock
# checking is off by default in verdict.sh, so a mutant whose whole subject is
# deadlock would otherwise come back OK and look inert when it is not.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch08-mut}"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(ls "$d"*.tla)
  module=$(basename "$tla" .tla)

  pcal "$tla" >/dev/null 2>&1

  if [ "$module" = "KitchenLocks" ]; then
    token=$(bash harness/verdict.sh -d "$tla" -c "$d$module.cfg" 2>/dev/null)
  else
    token=$(bash harness/verdict.sh "$tla" -c "$d$module.cfg" 2>/dev/null)
  fi
  rc=$?
  printf '%-4s %-14s %-20s rc=%s\n' "$id" "$module" "$token" "$rc"
done
