#!/usr/bin/env bash
# Re-run every ch11 reference through harness/verdict.sh and print the verdict
# token and the raw exit status. All five must read OK and rc=0.
#
# Usage:  bash exercises/ch11/reports/run-refs.sh
#
# Run it from the repo root. No pipeline into an early-exiting consumer
# (bead tla-kr9).

set -uo pipefail

for m in Odometer StepProbe Thermostat TankFarm Airlock; do
  token=$(bash harness/verdict.sh "exercises/ch11/references/$m.tla" \
    -c "exercises/ch11/references/$m.cfg" 2>/dev/null)
  rc=$?
  printf '%-12s %-22s rc=%s\n' "$m" "$token" "$rc"
done
