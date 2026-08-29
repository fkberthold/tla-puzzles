#!/usr/bin/env bash
# Re-run every ch13 reference through harness/verdict.sh and print the verdict
# token and the raw exit status. All four must read OK and rc=0.
#
# Usage:  bash exercises/ch13/reports/run-refs.sh
#
# Run it from the repo root. Every reference here is more than one file, and
# none of the extra files is named on the command line: TLC resolves them from
# the directory the named module sits in. That is the property the chapter
# teaches, so this script exercises it rather than working around it.
#
# No pipeline into an early-exiting consumer (bead tla-kr9).

set -uo pipefail

for m in Dock Beacon Cellar Garage; do
  token=$(bash harness/verdict.sh "exercises/ch13/references/$m.tla" \
    -c "exercises/ch13/references/$m.cfg" 2>/dev/null)
  rc=$?
  printf '%-10s %-22s rc=%s\n' "$m" "$token" "$rc"
done
