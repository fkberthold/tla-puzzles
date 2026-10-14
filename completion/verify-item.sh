#!/usr/bin/env bash
# Run a completion item's machines against the claims the learner wrote, and
# say which claim is weak rather than only that one is.
#
# Usage: bash completion/verify-item.sh completion/<family>/<NN>-<slug>
#
# The item's EXPECT file is tab-delimited, one `stem<TAB>rc` row per machine,
# in the order the item's PROMPT.md lists them. Every stem names a .tla and a
# .cfg of the same name in the item's work/ directory. The exit code is TLC's
# own, taken from harness/verdict.sh, which reads nothing from TLC's console.
#
# Exit: 0 if every machine reported the code EXPECT records, 1 otherwise.
#
# WHY TWO OF THE MACHINES ARE MEANT TO FAIL. A claim that passes the correct
# machine can still say nothing at all, and `TRUE` is the case that proves it.
# So an item carries broken machines whose job is to be caught, and a run that
# comes back all zeros is the failure this script exists to name.
set -u

item="${1:?item directory}"
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
verdict="$here/harness/verdict.sh"
work="$item/work"
expect="$item/EXPECT"

for required in "$verdict" "$expect" "$work"; do
  if [ ! -e "$required" ]; then
    echo "$0: no $required" >&2
    exit 1
  fi
done

scratch="${TMPDIR:-/tmp}/completion-verify-$$"
mkdir -p "$scratch"
trap 'rm -rf "$scratch"' EXIT

printf '%-14s %4s  %-20s %-10s %s\n' machine rc token distinct verdict
bad=0
codes=""

while IFS=$'\n' read -r row; do
  case "$row" in ""|\#*) continue ;; esac
  stem="${row%%	*}"
  want="${row##*	}"
  log="$scratch/$stem.log"
  rc=0
  token="$("$verdict" -c "$work/$stem.cfg" -t 180 --scratch "$scratch/$stem" \
    --log "$log" "$work/$stem.tla" 2>/dev/null)" || rc=$?
  distinct="$(grep -oE '[0-9]+ distinct states' "$log" 2>/dev/null | tail -1 | cut -d' ' -f1)"
  if [ "$rc" = "$want" ]; then
    mark="ok"
  else
    mark="WANTED $want"
    bad=1
  fi
  printf '%-14s %4s  %-20s %-10s %s\n' "$stem" "$rc" "$token" "${distinct:--}" "$mark"
  codes="${codes}${codes:+, }${rc}"
done < "$expect"

echo
echo "signature: $codes"

if [ "$bad" = 0 ]; then
  echo "OK: every machine reported the code the item records."
  exit 0
fi

case "$codes" in
  *150*) echo "A machine did not parse. A FILL_IN marker is still in Claims.tla, or what replaced it is not a formula." ;;
  0*0*0) echo "Every machine passed, including the broken ones, so at least one claim says nothing. TRUE scores this." ;;
  *) echo "Read the item's PROMPT.md for which machine answers to which claim." ;;
esac
exit 1
