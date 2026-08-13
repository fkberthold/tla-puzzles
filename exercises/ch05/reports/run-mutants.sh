#!/usr/bin/env bash
# Run every seeded ch05 mutant through harness/verdict.sh and print one row
# per mutant: id, module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch05/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch05-mut`, matching the seeder's default.
#
# Every mutant directory carries both a `.tla` and a `.cfg`, whichever one the
# mutant actually edits. The `.tla` is re-translated unconditionally before
# the run: TLC checks the translation and not the algorithm comment, so an
# edit inside the PlusCal block does nothing until pcal has run again, and
# re-translating an already-current `.tla` (a `.cfg`-only mutant) is a no-op
# that costs nothing but a second pcal pass.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch05-mut}"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  tla=$(ls "$d"*.tla)
  module=$(basename "$tla" .tla)
  if grep -q -- "--algorithm" "$tla"; then
    pcal "$tla" >/dev/null 2>&1
  fi
  token=$(bash harness/verdict.sh "$tla" -c "$d$module.cfg" 2>/dev/null)
  rc=$?
  printf '%-4s %-12s %-20s rc=%s\n' "$id" "$module" "$token" "$rc"
done
