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
  # A cfg saying CHECK_DEADLOCK TRUE is asking for the deadlock check, and
  # harness/verdict.sh refuses the run at 99 CHECK_DID_NOT_RUN unless the flag
  # is passed. Both reading/state-space/02-tickets and 03-chips carry that
  # keyword and discuss what it covers, so an author varying either one reaches
  # for it. drill/temporal/verify-item.sh already does this and this is its
  # logic. Measured by the tla-gz6m author: rc 99 without the flag.
  flags=()
  if grep -q '^CHECK_DEADLOCK TRUE' "$work/$stem.cfg"; then flags=(-d); fi
  token="$("$verdict" "${flags[@]}" -c "$work/$stem.cfg" -t 180 \
    --scratch "$scratch/$stem" --log "$log" "$work/$stem.tla" 2>/dev/null)" || rc=$?
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

# A 150 has two causes that look identical in the code and are nothing alike to
# the person reading it. One is work not started. The other is a correct idea
# written in a way SANY rejects, and the tla-vzch author measured a real case:
# `pulls \div 2 * 2 = pulls` does not parse on this build, because \div and *
# share a precedence level, while the parenthesised form scores the reference
# signature. Reporting that as a surviving marker tells the learner they have
# not begun.
case "$codes" in
  *150*)
    # Comments stripped FIRST. Claims.tla's own header says "Replace each
    # FILL_IN marker with a TLA+ formula", so a grep over the raw file matches
    # the instruction and reports every parse failure as work not started.
    # Measured: that is what this check did on its first version.
    uncommented="$(sed 's/\\[*].*//' "$work/Claims.tla")"
    if grep -q 'FILL_IN' <<<"$uncommented"; then
      echo "A machine did not parse, and Claims.tla still carries a FILL_IN marker."
    else
      echo "A machine did not parse, and no FILL_IN marker is left, so what you wrote is not a formula SANY accepts."
      # SANY's own sentence, which names the operators and the line. Four
      # shapes cover what a filled-in claim actually trips. Taken from a
      # measured log: "Precedence conflict between ops \div in block line 25,
      # col 29 to line 25, col 32 of module Claims and *."
      hits="$(grep -hE 'Precedence conflict|Unknown operator|Encountered|was not declared' \
        "$scratch"/*.log 2>/dev/null || true)"
      # `| head -3` would close the pipe on the third line and SIGPIPE sort,
      # which is 141 under pipefail. This script runs under `set -u` alone and
      # throws the status away, so it was harmless here, and it was the one
      # live site the pipefail ban found when bead tla-l1en widened that gate
      # to this tree. Capturing first and slicing from a here-string removes
      # the live writer, so there is nothing left to signal. Byte-identical
      # output, measured over five inputs including the empty one.
      ranked="$(printf '%s\n' "$hits" | sed -n 's/^[[:space:]]*/  /p' | sort -u)"
      head -3 <<<"$ranked"
    fi
    ;;
  0*0*0) echo "Every machine passed, including the broken ones, so at least one claim says nothing. TRUE scores this." ;;
  *) echo "Read the item's PROMPT.md for which machine answers to which claim." ;;
esac
exit 1
