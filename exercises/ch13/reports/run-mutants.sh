#!/usr/bin/env bash
# Run every seeded ch13 mutant through harness/verdict.sh and print one row per
# mutant: id, root module, verdict token, raw exit status.
#
# Usage:  bash exercises/ch13/reports/run-mutants.sh [MUT_DIR]
#
# Run it from the repo root, after reports/mutants.py has seeded MUT_DIR.
# MUT_DIR defaults to `.ch13-mut`, matching the seeder's default.
#
# No pcal step. Chapter 13 is pure TLA+, so what the seeder wrote is what TLC
# reads.
#
# The module TLC is pointed at comes from the ROOT file the seeder drops beside
# the group, because the edited file is often NOT the root. Breaking Signal.tla
# and running Beacon.tla is the shape of half this chapter's failures.
#
# Each group is run with the mutant directory as the working directory, so TLC
# resolves the group's other modules the way a learner's run resolves starters/.
#
# A mutant that does not parse is still a mutant. PARSE_ERROR is one of the
# verdicts this table is measuring, so nothing here short-circuits on it.
#
# No pipeline into an early-exiting consumer anywhere in this file. Under
# `set -o pipefail` that returns 141 and reports a present pattern as absent
# (bead tla-kr9).

set -uo pipefail

MUT_DIR="${1:-.ch13-mut}"
HARNESS="$PWD/harness/verdict.sh"

for d in "$MUT_DIR"/*/; do
  id=$(basename "$d")
  root=$(cat "$d/ROOT")
  token=$(cd "$d" && bash "$HARNESS" "$root.tla" -c "$root.cfg" 2>/dev/null)
  rc=$?
  printf '%-4s %-10s %-22s rc=%s\n' "$id" "$root" "$token" "$rc"
done
