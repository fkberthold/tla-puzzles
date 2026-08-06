#!/usr/bin/env bash
# Run one snippet and report its exit code.
#   ./run.sh Almanac.tla            -> uses Almanac.cfg
#   ./run.sh Observatory.tla Probe.cfg
# Exit codes that matter: 0 = all checks passed, 12 = a property or invariant
# was violated, 10 = a TLCGet/postcondition assertion failed, 255 = parse error.
cd "$(dirname "$0")" || exit 1
mod="$1"
cfg="${2:-${mod%.tla}.cfg}"
out=$(tlc -workers 1 -config "$cfg" "$mod" 2>&1)
rc=$?
echo "$out"
echo "=== $mod ($cfg) rc=$rc"
rm -f ./*_TTrace_*.tla ./*_TTrace_*.bin 2>/dev/null
exit $rc
