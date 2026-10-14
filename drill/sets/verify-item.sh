#!/usr/bin/env bash
# Run every module in an item's verify/ directory through the harness verdict
# channel and print one line per module: stem, raw TLC exit code, verdict
# token, distinct states.
#
# Usage: bash drill/sets/verify-item.sh drill/sets/<NN>-<slug> [SCRATCH]
#
# Every module in this family has a config of its own name beside it, which
# is the pairing harness/drill-gate.sh checks. A config that says
# CHECK_DEADLOCK TRUE gets the -d flag, as the gate passes it. The exit code
# is TLC's own, taken from harness/verdict.sh, which reads nothing from TLC's
# console. The distinct-state count is read from the log, which is why it
# sits in a separate column from the verdict.
set -u

item="${1:?item directory}"
scratch="${2:-${TMPDIR:-/tmp}/drill-sets-verify-$$}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
verdict="$here/harness/verdict.sh"
vdir="$item/verify"
mkdir -p "$scratch"

printf '%-24s %4s  %-22s %s\n' module rc token distinct
for mod in "$vdir"/*.tla; do
  stem="$(basename "$mod" .tla)"
  cfg="$vdir/$stem.cfg"
  log="$scratch/$stem.log"
  rc=0
  flags=()
  if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "$cfg"; then flags=(-d); fi
  token="$("$verdict" "${flags[@]}" -c "$cfg" -t 120 --scratch "$scratch/$stem" --log "$log" "$mod")" || rc=$?
  distinct="$(grep -oE '[0-9]+ distinct states' "$log" | tail -1 | cut -d' ' -f1)"
  printf '%-24s %4s  %-22s %s\n' "$stem" "$rc" "$token" "${distinct:--}"
done
