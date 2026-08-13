#!/usr/bin/env bash
# Re-run every ch08 reference through harness/verdict.sh and print the verdict
# token and the raw exit status. All five must read OK.
#
# Usage:  bash exercises/ch08/reports/run-refs.sh
#
# Run it from the repo root. The references ship already translated, so this
# does not call pcal; reports/run-mutants.sh does, because a mutant edits the
# PlusCal block and TLC only ever reads the translation.
#
# KitchenLocks is the one reference that needs -d. Deadlock checking is off by
# default in verdict.sh, and a spec whose whole subject is deadlock has to ask
# for it. See EXERCISES.md, exercise 2.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

run_one() {
  local m="$1"
  shift
  local token rc
  token=$(bash harness/verdict.sh "$@" "exercises/ch08/references/$m.tla" \
    -c "exercises/ch08/references/$m.cfg" 2>/dev/null)
  rc=$?
  printf '%-14s %-20s rc=%s\n' "$m" "$token" "$rc"
}

run_one SeatDesk
run_one KitchenLocks -d
run_one Cloakroom
run_one StampDesk
run_one BellTower
