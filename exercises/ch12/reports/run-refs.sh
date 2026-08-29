#!/usr/bin/env bash
# Re-run every ch12 reference through harness/verdict.sh and print the verdict
# token and the raw exit status. All five must read OK and rc=0.
#
# Usage:  bash exercises/ch12/reports/run-refs.sh
#
# Run it from the repo root. GlazingBench is run with `-d`, which is the flag
# exercise 3's own how-to-run line carries; see the note in run-mutants.sh.
# No pipeline into an early-exiting consumer (bead tla-kr9).

set -uo pipefail

for m in SeedDrill Apiary Drawbridge Capper; do
  token=$(bash harness/verdict.sh "exercises/ch12/references/$m.tla" \
    -c "exercises/ch12/references/$m.cfg" 2>/dev/null)
  rc=$?
  printf '%-14s %-22s rc=%s\n' "$m" "$token" "$rc"
done

token=$(bash harness/verdict.sh -d "exercises/ch12/references/GlazingBench.tla" \
  -c "exercises/ch12/references/GlazingBench.cfg" 2>/dev/null)
rc=$?
printf '%-14s %-22s rc=%s\n' "GlazingBench" "$token" "$rc"
