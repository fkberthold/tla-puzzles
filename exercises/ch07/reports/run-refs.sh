#!/usr/bin/env bash
# Re-run every ch07 reference through harness/verdict.sh and print the verdict
# token and the raw exit status.
#
# Usage:  bash exercises/ch07/reports/run-refs.sh
#
# Run it from the repo root. No pipeline into an early-exiting consumer
# (bead tla-kr9).
#
# Six rows for five modules. Jugs is checked twice, once per config, because
# its exercise states one outcome for each. Four rows read OK, and the
# Jugs/Jugs row reads SAFETY_VIOLATION on purpose: that exercise inverts its
# invariant so a violation is the answer rather than a defect.

set -uo pipefail

REF=exercises/ch07/references

run_one() {
  local module="$1" cfg="$2" token rc
  token=$(bash harness/verdict.sh "$REF/$module.tla" -c "$REF/$cfg.cfg" 2>/dev/null)
  rc=$?
  printf '%-12s %-12s %-20s rc=%s\n' "$module" "$cfg" "$token" "$rc"
}

run_one Depot Depot
run_one Sluice Sluice
run_one Jugs Jugs
run_one Jugs JugsEven
run_one BoxOffice BoxOffice
run_one Ferry Ferry
